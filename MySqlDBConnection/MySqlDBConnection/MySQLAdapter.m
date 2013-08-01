//
//  MySQLAdapter.m
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//

#import "MySQLAdapter.h"

#import <mysql.h>

static dispatch_queue_t induction_mysql_adapter_queue() {
    static dispatch_queue_t _induction_mysql_adapter_queue;
    if (_induction_mysql_adapter_queue == NULL) {
        _induction_mysql_adapter_queue = dispatch_queue_create("com.mysqldatabase.mysql.adapter.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return _induction_mysql_adapter_queue;
}

NSString * const MySQLErrorDomain = @"com.ht.client.mysql.error";

@implementation MySQLAdapter

+ (NSString *)localizedName {
    return NSLocalizedString(@"MySQL", nil);
}

+ (NSString *)primaryURLScheme {
    return @"mysql";
}

+ (BOOL)canConnectToURL:(NSURL *)url {
    return [[url scheme] isEqualToString:[self primaryURLScheme]];
}

+ (void)connectToURL:(NSURL *)url 
             success:(void (^)(id<DBConnection>))success 
             failure:(void (^)(NSError *))failure 
{
    dispatch_async(induction_mysql_adapter_queue(), ^(void) {
        MySQLConnection *connection = [[MySQLConnection alloc] initWithURL:url];
        NSError *error = nil;
        BOOL connected = [connection open:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (connected) {
                if (success) {
                    success(connection);
                }
            } else {
                if (failure) {
                    failure(error);
                }
            }
        });
    });
}

@end

#pragma mark -

@interface MySQLConnection () {
@private
    MYSQL *_mysql_connection;
    __strong NSURL *_url;
    __strong MySQLDatabase *_database;
}

@end

@implementation MySQLConnection
@synthesize url = _url;
@synthesize database = _database;

- (void)dealloc {
    if (_mysql_connection) {
        mysql_close(_mysql_connection);
        _mysql_connection = NULL;
    }
}

- (id)initWithURL:(NSURL *)url {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _url = url;
    
    return self;
}

- (BOOL)open:(NSError *__autoreleasing *)error {
	[self close:nil];
        
    _mysql_connection = mysql_init(NULL);
    
    const char *host = [[_url host] UTF8String];
    const char *user = [[_url user] UTF8String];
    const char *password = [[_url password] UTF8String];
    const char *database = [[_url lastPathComponent] UTF8String];
    unsigned int port = [[_url port] unsignedIntValue];
    const char *socket = MYSQL_UNIX_ADDR;
    
    if (!mysql_real_connect(_mysql_connection, host, user, password, database, port, socket, 0)) {
        NSMutableDictionary *mutableUserInfo = [NSMutableDictionary dictionary];
        [mutableUserInfo setValue:NSLocalizedString(@"Connection Error", nil) forKey:NSLocalizedDescriptionKey];
        [mutableUserInfo setValue:[NSString stringWithUTF8String:mysql_error(_mysql_connection)] forKey:NSLocalizedRecoverySuggestionErrorKey];
        [mutableUserInfo setValue:_url forKey:NSURLErrorKey];
        NSUInteger code = mysql_errno(_mysql_connection);
        *error = [[NSError alloc] initWithDomain:MySQLErrorDomain code:code userInfo:mutableUserInfo];
        return NO;
    }
    
    if ([[NSString stringWithUTF8String:database] length] != 0) {
        _database = [[MySQLDatabase alloc] initWithConnection:self name:[NSString stringWithUTF8String:database] stringEncoding:NSUTF8StringEncoding];
        mysql_select_db(_mysql_connection, [[_database name] UTF8String]);
    }
    
    return YES;
}

- (BOOL)close:(NSError *__autoreleasing *)error {
    if (_mysql_connection == NULL) { 
        return NO; 
    }
    
    mysql_close(_mysql_connection);

	return YES;
}

- (BOOL)reset:(NSError *__autoreleasing *)error {
    if (_mysql_connection == NULL) { 
        return NO; 
    }
    
    mysql_refresh(_mysql_connection, 0);
    
    return mysql_stat(_mysql_connection) == MYSQL_STATUS_READY;
}

- (id <SQLResultSet>)resultSetByExecutingSQL:(NSString *)SQL 
                                       error:(NSError *__autoreleasing *)error
{
    MYSQL_RES *mysql_result = nil;
    NSInteger status = mysql_query(_mysql_connection, [SQL UTF8String]);
    if (status == 0) {
		if (mysql_field_count(_mysql_connection) != 0) {
			mysql_result = mysql_store_result(_mysql_connection);
		} else {
			return nil;
		}
	} else {
//        *error = [[NSError alloc] initWithDomain:MySQLErrorDomain code:mysql_errno(_mysql_connection) userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:mysql_error(_mysql_connection)] forKey:NSLocalizedDescriptionKey]];
        
        return nil;
	}
    
    return [[MySQLResultSet alloc] initWithMySQLResult:mysql_result];
}

- (void)executeSQL:(NSString *)SQL 
           success:(void (^)(id<SQLResultSet>, NSTimeInterval))success 
           failure:(void (^)(NSError *))failure
{
    dispatch_async(induction_mysql_adapter_queue(), ^(void) {
        MYSQL_RES *mysql_result = nil;
        
        CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
        NSInteger status = mysql_query(_mysql_connection, [SQL UTF8String]);
        CFAbsoluteTime endTime = CFAbsoluteTimeGetCurrent();
        
        MySQLResultSet *resultSet = [[MySQLResultSet alloc] initWithMySQLResult:mysql_result];
        NSError *error = nil;
        
        if (status == 0) {
            if (mysql_field_count(_mysql_connection) != 0) {
                mysql_result = mysql_store_result(_mysql_connection);
                resultSet = [[MySQLResultSet alloc] initWithMySQLResult:mysql_result];
            }
        } else {
            error = [[NSError alloc] initWithDomain:MySQLErrorDomain code:mysql_errno(_mysql_connection) userInfo:[NSDictionary dictionaryWithObject:[NSString stringWithUTF8String:mysql_error(_mysql_connection)] forKey:NSLocalizedDescriptionKey]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else {
                if (success) {
                    success(resultSet, (endTime - startTime));
                }
            }
        });
    });
}


- (NSArray *)availableDatabases {
    NSString *SQL = @"SHOW DATABASES";
    NSMutableArray *mutableDatabases = [[NSMutableArray alloc] init];
    [[[self resultSetByExecutingSQL:SQL error:nil] tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MySQLDatabase *database = [[MySQLDatabase alloc] initWithConnection:self name:[(MySQLTuple *)obj valueForKey:@"Database"] stringEncoding:NSUTF8StringEncoding];
        [mutableDatabases addObject:database];
    }];
    
    return mutableDatabases;
}

- (void)connectToDatabase:(id <DBDatabase>)database error:(NSError **)error{
    [self willChangeValueForKey:@"database"];
    
    if ([[_url lastPathComponent] isEqualToString:@""]) {
        _url = [_url URLByAppendingPathComponent:[database name]];
    } else {
        _url = [[_url URLByDeletingLastPathComponent] URLByAppendingPathComponent:[database name]];
    }
    
    [self open:error];
    [self didChangeValueForKey:@"database"];
}

@end

#pragma mark -

@interface MySQLDatabase () {
@private
    __strong MySQLConnection *_connection;
    __strong NSString *_name;
    __strong NSArray *_tables;
    NSStringEncoding _stringEncoding;
}
@end

@implementation MySQLDatabase
@synthesize connection = _connection;
@synthesize name = _name;
@synthesize stringEncoding = _stringEncoding;
@synthesize tables = _tables;

- (id)initWithConnection:(id<SQLConnection>)connection name:(NSString *)name stringEncoding:(NSStringEncoding)stringEncoding 
{
    self = [super init];
    if (!self) {
        return nil;
    }
        
    _connection = connection;
    _name = name;
    _stringEncoding = NSUTF8StringEncoding;
    
    
    NSString *SQL = @"SHOW TABLES";
    MySQLResultSet *resultSet = [_connection resultSetByExecutingSQL:SQL error:nil];
    NSString *fieldName = [[[resultSet fields] lastObject] name];
    NSMutableArray *mutableTables = [NSMutableArray array];
    [[resultSet tuples] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        MySQLTable *table = [[MySQLTable alloc] initWithDatabase:self name:[(MySQLTuple *)obj valueForKey:fieldName] stringEncoding:NSUTF8StringEncoding];
        [mutableTables addObject:table];
    }];
    
    _tables = mutableTables;
    
    return self;
}

- (NSString *)description {
    return _name;
}

- (NSDictionary *)metadata {
    return nil;
}

- (NSUInteger)numberOfDataSourceGroups {
    return 1;
}

- (NSString *)dataSourceGroupAtIndex:(NSUInteger)index {
    return NSLocalizedString(@"Tables", nil);
}

- (NSUInteger)numberOfDataSourcesInGroup:(NSString *)group {
    return [_tables count];
}

- (id <DBDataSource>)dataSourceInGroup:(NSString *)group atIndex:(NSUInteger)index {
    return [_tables objectAtIndex:index];
}

@end

#pragma mark -

@interface MySQLTable () {
@private
    __strong MySQLDatabase *_database;
    __strong NSString *_name;
    NSStringEncoding _stringEncoding;
}
@end

@implementation MySQLTable
@synthesize name = _name;
@synthesize stringEncoding = _stringEncoding;
@synthesize database = _database;

- (id)initWithDatabase:(id<SQLDatabase>)database 
                  name:(NSString *)name 
        stringEncoding:(NSStringEncoding)stringEncoding
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _database = database;
    _name = name;
    _stringEncoding = stringEncoding;
    
    return self;
}

- (NSString *)description {
    return _name;
}

- (NSUInteger)numberOfRecords {
    NSString *SQL = [NSString stringWithFormat:@"SELECT COUNT(*) as count FROM %@", _name];
    return MAX([[[[[[_database connection] resultSetByExecutingSQL:SQL error:nil] recordsAtIndexes:[NSIndexSet indexSetWithIndex:0]] lastObject] valueForKey:@"count"] integerValue], 0); 
}

#pragma mark -

- (void)fetchResultSetForRecordsAtIndexes:(NSIndexSet *)indexes 
                                  success:(void (^)(id<DBResultSet>))success 
                                  failure:(void (^)(NSError *))failure 
{
    // TODO Proper empty set handling
    if ([indexes count] == 0) {
        if (success) {
            success(nil);
        }
        return;
    }
    
    NSString *SQL = [NSString stringWithFormat:@"SELECT * FROM %@ LIMIT %d OFFSET %d ", _name, [indexes count], [indexes firstIndex]];
    [[_database connection] executeSQL:SQL success:^(id<SQLResultSet> resultSet, __unused NSTimeInterval elapsedTime) {
        if (success) {
            success(resultSet);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark -

- (void)fetchResultSetForQuery:(NSString *)query 
                       success:(void (^)(id<DBResultSet>, NSTimeInterval))success 
                       failure:(void (^)(NSError *))failure 
{
    [[_database connection] executeSQL:query success:^(id<SQLResultSet> resultSet, NSTimeInterval elapsedTime) {
        if (success) {
            success(resultSet, elapsedTime);
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark -

- (void)fetchResultSetForDimension:(NSExpression *)dimension
                          measures:(NSArray *)measures
                           success:(void (^)(id <DBResultSet> resultSet))success
                           failure:(void (^)(NSError *error))failure
{
    // TODO
}

@end

#pragma mark -

@interface MySQLField () {
@private
    NSUInteger _index;
    __strong NSString *_name;
    DBValueType _type;
    NSUInteger _size;
}
@end

@implementation MySQLField
@synthesize index = _index;
@synthesize name = _name;
@synthesize type = _type;
@synthesize size = _size;

+ (MySQLField *)fieldInMySQLResult:(void *)result 
                           atIndex:(NSUInteger)fieldIndex 
{
    MySQLField *field = [[MySQLField alloc] init];
    field->_index = fieldIndex;
    
    MYSQL_FIELD *mysql_field = mysql_fetch_field_direct(result, (int)fieldIndex);
    field->_name = [NSString stringWithCString:mysql_field->name encoding:NSUTF8StringEncoding];
    if (!field->_name) {
        field->_name = @"";
    }
    
    switch (mysql_field->type) {
        case MYSQL_TYPE_BIT:
            field->_type = DBBooleanValue;
            break;
        case MYSQL_TYPE_SHORT:
        case MYSQL_TYPE_LONG:
        case MYSQL_TYPE_INT24:
        case MYSQL_TYPE_LONGLONG:
            field->_type = DBIntegerValue;
            break;
        case MYSQL_TYPE_FLOAT:
        case MYSQL_TYPE_DOUBLE:
        case MYSQL_TYPE_DECIMAL:
        case MYSQL_TYPE_NEWDECIMAL:
            field->_type = DBDecimalValue;
            break;
        case MYSQL_TYPE_ENUM:
            field->_type = DBEnumValue;
            break;
        case MYSQL_TYPE_SET:
            field->_type = DBSetValue;
            break;
        case MYSQL_TYPE_DATE:
            field->_type = DBDateValue;
            break;
        case MYSQL_TYPE_DATETIME:
            field->_type = DBDateTimeValue;
            break;
        case MYSQL_TYPE_TINY_BLOB:
        case MYSQL_TYPE_MEDIUM_BLOB:
        case MYSQL_TYPE_LONG_BLOB:
        case MYSQL_TYPE_BLOB:
            field->_type = DBBlobValue;
            break;
        case MYSQL_TYPE_GEOMETRY:
            field->_type = DBGeometryValue;
        default:
            field->_type = DBStringValue;
            break;
    }
     
    return field;
}

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding 
{
    id value = nil;
    
    if (bytes != NULL) {
        switch (_type) {
            case DBBooleanValue:
                value = [NSNumber numberWithBool:((*(char *)bytes) == 't')];
                break;
            case DBIntegerValue:
                value = [NSNumber numberWithInteger:[[NSString stringWithUTF8String:bytes] integerValue]];
                break;
            case DBDecimalValue:
                value = [NSNumber numberWithDouble:[[NSString stringWithUTF8String:bytes] doubleValue]];
                break;
            case DBStringValue:
                value = [NSString stringWithUTF8String:bytes];
                break;
            case DBDateValue:
            case DBDateTimeValue:
                value = [NSString stringWithUTF8String:bytes];
                break;
            default:
                break;
        }
    }
    
    if (!value) {
        value = [NSNull null];
    }
    
    return value;
}

@end

#pragma mark -

@interface MySQLTuple () {
@private
    NSUInteger _index;
    __strong NSDictionary *_valuesKeyedByFieldName;
}
@end

@implementation MySQLTuple
@synthesize index = _index;

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _valuesKeyedByFieldName = keyedValues;
    
    return self;
}

- (id)valueForKey:(NSString *)key {
    return [_valuesKeyedByFieldName objectForKey:key];
}

@end

#pragma mark -

@interface MySQLResultSet () {
@private
    MYSQL_RES *_mysql_result;
    NSUInteger _tuplesCount;
    NSUInteger _fieldsCount;
    __strong NSArray *_fields;
    __strong NSDictionary *_fieldsKeyedByName;
    __strong NSArray *_tuples;
}

- (NSArray *)tupleValuesAtIndex:(NSUInteger)tupleIndex;

@end

@implementation MySQLResultSet
@synthesize fields = _fields;
@synthesize tuples = _tuples;

- (void)dealloc {
    if (_mysql_result) {
        _mysql_result = NULL;
    }    
}

- (id)initWithMySQLResult:(void *)result {
    if (result == NULL) {
        return nil;
    }
    
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _mysql_result = result;
    _tuplesCount = mysql_num_rows(_mysql_result);
    _fieldsCount = mysql_num_fields(_mysql_result);
    
    NSMutableArray *mutableFields = [[NSMutableArray alloc] initWithCapacity:_fieldsCount];
    NSIndexSet *fieldIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _fieldsCount)];
    [fieldIndexSet enumerateIndexesWithOptions:NSEnumerationConcurrent usingBlock:^(NSUInteger fieldIndex, BOOL *stop) {
        MySQLField *field = [MySQLField fieldInMySQLResult:result atIndex:fieldIndex];
        [mutableFields addObject:field];
    }];
    _fields = mutableFields;
    _fieldsCount = [_fields count];
    
    NSMutableDictionary *mutableKeyedFields = [[NSMutableDictionary alloc] initWithCapacity:_fieldsCount];
    for (MySQLField *field in _fields) {
        [mutableKeyedFields setObject:field forKey:field.name];
    }
    _fieldsKeyedByName = mutableKeyedFields;
    
    NSMutableArray *mutableTuples = [[NSMutableArray alloc] initWithCapacity:_tuplesCount];
    NSIndexSet *tupleIndexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _tuplesCount)];
    [tupleIndexSet enumerateIndexesWithOptions:0 usingBlock:^(NSUInteger tupleIndex, BOOL *stop) {
        NSDictionary *valuesKeyedByFieldName = [NSDictionary dictionaryWithObjects:[self tupleValuesAtIndex:tupleIndex] forKeys:[_fields valueForKeyPath:@"name"]];
        MySQLTuple *tuple = [[MySQLTuple alloc] initWithValuesKeyedByFieldName:valuesKeyedByFieldName];
        [mutableTuples addObject:tuple];
    }];
    
    _tuples = mutableTuples;
    
    return self;
}

- (NSArray *)tupleValuesAtIndex:(NSUInteger)tupleIndex {
    mysql_data_seek(_mysql_result, tupleIndex);
    MYSQL_ROW row = mysql_fetch_row(_mysql_result);
    
    NSMutableArray *mutableValues = [NSMutableArray arrayWithCapacity:_fieldsCount];
    for (MySQLField *field in _fields) {        
        [mutableValues addObject:[field objectForBytes:row[field.index] length:sizeof(row[field.index]) encoding:NSUTF8StringEncoding]];
    }
    
    return mutableValues;
}

- (NSUInteger)numberOfFields {
    return _fieldsCount;
}

- (NSUInteger)numberOfRecords {
    return _tuplesCount;
}

- (NSArray *)recordsAtIndexes:(NSIndexSet *)indexes {
    return [_tuples objectsAtIndexes:indexes];
}

- (NSString *)identifierForTableColumnAtIndex:(NSUInteger)index {
    MySQLField *field = [_fields objectAtIndex:index];
    return [field name];
}

- (DBValueType)valueTypeForTableColumnAtIndex:(NSUInteger)index {
    MySQLField *field = [_fields objectAtIndex:index];
    return [field type];
}

- (NSSortDescriptor *)sortDescriptorPrototypeForTableColumnAtIndex:(NSUInteger)index {
    MySQLField *field = [_fields objectAtIndex:index];
    if ([field type] == DBStringValue) {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES selector:@selector(localizedStandardCompare:)];
    } else {
        return [NSSortDescriptor sortDescriptorWithKey:[field name] ascending:YES];
    }
}

@end
