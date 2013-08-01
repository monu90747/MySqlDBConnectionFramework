//
//  MySqlDBConnection.m
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//
#import "MySqlDBConnection.h"

static dispatch_queue_t mysql_connection_adapter_queue() {
    static dispatch_queue_t _mysql_connection_adapter_queue;
    if (_mysql_connection_adapter_queue == NULL) {
        _mysql_connection_adapter_queue = dispatch_queue_create("com.mysqldatabase.mysql.adapter.queue", DISPATCH_QUEUE_SERIAL);
    }
    
    return _mysql_connection_adapter_queue;
}

static NSString * const kInductionPreviousConnectionURLKey = @"com.induction.connection.previous.url";

static NSString * DBURLStringFromComponents(NSString *scheme, NSString *host, NSString *user, NSString *password, NSNumber *port, NSString *database) {
    NSMutableString *mutableURLString = [NSMutableString stringWithFormat:@"%@://", scheme];
    if (user && [user length] > 0) {
        [mutableURLString appendFormat:@"%@", user];
        if (password && [password length] > 0) {
            [mutableURLString appendFormat:@":%@", password];
        }
        [mutableURLString appendString:@"@"];
    }
    
    if (host && [host length] > 0) {
        [mutableURLString appendString:host];
    }
    if (port && [port integerValue] > 0) {
        [mutableURLString appendFormat:@":%ld", [port integerValue]];
    }
    if (database && [database length] > 0 && [host length] > 0) {
        [mutableURLString appendFormat:@"/%@", [database stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]]];
    }
    return [NSString stringWithString:mutableURLString];
}


@implementation MySqlDBConnection
@synthesize connecting = _connecting;
@dynamic isConnecting;
@synthesize connectionURL = _connectionURL;
@synthesize delegate=_delegate;

- (NSDictionary *)dictionaryForTableResultData:(NSArray*)tableFields Tuples:(NSArray*)tableTuples{
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    NSMutableArray *fields = [[NSMutableArray alloc] init];
    for(int i=0;i<[tableFields count];i++){
        MySQLField *field = [tableFields objectAtIndex:i];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setObject:[NSString stringWithFormat:@"%lu",(unsigned long)field.index] forKey:@"index"];
        [dict setObject:field.name forKey:@"name"];
        [fields addObject:dict];
    }
    [resultDict setObject:fields forKey:@"fields"];
    NSMutableArray *tuples = [[NSMutableArray alloc] init];
    for (int j=0; j<[tableTuples count]; j++) {
        MySQLTuple *tuple = [tableTuples objectAtIndex:j];
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for(int i=0;i<[tableFields count];i++){
            MySQLField *field = [tableFields objectAtIndex:i];
            [dict setObject:[tuple valueForKey:field.name] forKey:field.name];
        }
        [tuples addObject:dict];
    }
    [resultDict setObject:tuples forKey:@"tuples"];
    return resultDict;
}

#pragma mark - Connection method

- (void)connectToMySqlWithScheme:(NSString*)scheme Host:(NSString*)host UserName:(NSString*)user Password:(NSString*)password DatabseName:(NSString*)database PortNumber:(int)portNo{
    NSNumber *port=[NSNumber numberWithInt:portNo];
    self.connectionURL = [NSURL URLWithString:DBURLStringFromComponents(scheme, host, user, password, port, database)];
    self.connecting = YES;
    id <DBAdapter> adapter = (id <DBAdapter>)[MySQLAdapter class];
    if ([adapter canConnectToURL:self.connectionURL]) {
        [adapter connectToURL:self.connectionURL success:^(id <DBConnection> connection) {
            if([_delegate respondsToSelector:@selector(mySqlConnectionSuccess:Error:)]){
                [_delegate mySqlConnectionSuccess:YES Error:nil];
            }
        } failure:^(NSError *error){
            self.connecting = NO;
            if([_delegate respondsToSelector:@selector(mySqlConnectionSuccess:Error:)]){
                [_delegate mySqlConnectionSuccess:NO Error:error];
            }
        }];
    }
}

- (void)connectToMySqlWithScheme:(NSString*)scheme
                            Host:(NSString*)host
                        UserName:(NSString*)user
                        Password:(NSString*)password
                     DatabseName:(NSString*)database
                      PortNumber:(int)portNo
                   successResult:(void (^)(id <DBConnection> connection, id connectionURL))successResult
                   failureResult:(void (^)(NSError *error))failureResult
{   
    NSNumber *port=[NSNumber numberWithInt:portNo];
    self.connectionURL = [NSURL URLWithString:DBURLStringFromComponents(scheme, host, user, password, port, database)];
    self.connecting = YES;
    id <DBAdapter> adapter = (id <DBAdapter>)[MySQLAdapter class];
    if ([adapter canConnectToURL:self.connectionURL]){
        [adapter connectToURL:self.connectionURL success:^(id <DBConnection> connection) {
            if(successResult){
                successResult(connection,self.connectionURL);
            }
        } failure:^(NSError *error){
            if(failureResult){
                failureResult(error);
            }
        }];
    }
}

#pragma mark - Execute any query

- (void)executeQuery:(NSString*)sql{
    if(self.connecting){
        MySQLConnection *conn = [[MySQLConnection alloc]initWithURL:self.connectionURL];
        [conn open:nil];
        [conn executeSQL:sql success:^(id<SQLResultSet> resultSet, NSTimeInterval elapsedTime) {
            
            NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
            if(resultSet!=NULL){
                resultDict = (NSMutableDictionary*)[self dictionaryForTableResultData:resultSet.fields Tuples:resultSet.tuples];
            }
            else{
                [resultDict setObject:@"success" forKey:@"result"];
            }
            [resultDict setObject:[NSString stringWithFormat:@"%f",elapsedTime] forKey:@"elapsed_time"];
            if([_delegate respondsToSelector:@selector(mySqlResult:Error:)]){
                [_delegate mySqlResult:resultDict Error:nil];
            }
            [conn close:nil];
        } failure:^(NSError *error){
            NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
            [resultDict setObject:@"Fail" forKey:@"result"];
            if([_delegate respondsToSelector:@selector(mySqlResult:Error:)]){
                [_delegate mySqlResult:resultDict Error:error];
            }
            [conn close:nil];
        }];
    }
    else{
        NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
        [resultDict setObject:@"Connection not available." forKey:@"result"];
        if([_delegate respondsToSelector:@selector(mySqlResult:Error:)]){
            [_delegate mySqlResult:resultDict Error:[NSError errorWithDomain:MySQLErrorDomain code:2002 userInfo:resultDict]];
        }
    }
}

- (void)executeQuery:(NSString *)sql
     successResult:(void (^)(id dict))successResult
     failureResult:(void (^)(NSError *error))failureResult{
    if(self.connecting){
        MySQLConnection *conn = [[MySQLConnection alloc]initWithURL:self.connectionURL];
        [conn open:nil];
        [conn executeSQL:sql success:^(id<SQLResultSet> resultSet, NSTimeInterval elapsedTime) {
            if(successResult){
                NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
                if(resultSet!=NULL){
                    resultDict = (NSMutableDictionary*)[self dictionaryForTableResultData:resultSet.fields Tuples:resultSet.tuples];
                }
                else{
                    [resultDict setObject:@"success" forKey:@"result"];
                }
                [resultDict setObject:[NSString stringWithFormat:@"%f",elapsedTime] forKey:@"elapsed_time"];
                successResult(resultDict);
            }
            [conn close:nil];
        } failure:^(NSError *error){
            if(failureResult){
                failureResult(error);
            }
            [conn close:nil];
        }];
    }else{
        NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
        [resultDict setObject:@"Connection not available." forKey:@"result"];
        NSError *error = [[NSError alloc] initWithDomain:MySQLErrorDomain code:2002 userInfo:resultDict];
        if(failureResult){
            failureResult(error);
        }
    }
}


#pragma mark - Fetch record

- (void)fetchAllRecordFromTable:(NSString*)table{
    NSString *sql = [NSString stringWithFormat:@"select * from %@;",table];
    [self executeQuery:sql];
}

- (void)fetchRecordFromTable:(NSString*)table Where:(NSString*)condition{
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@;",table,condition];
    [self executeQuery:sql];
}

- (void)fetchAllRecordFromTable:(NSString *)table
                        success:(void (^)(id dict))success
                        failure:(void (^)(NSError *error))failure{
    NSString *sql = [NSString stringWithFormat:@"select * from %@;",table];
    [self executeQuery:sql successResult:^(id dict) {
        if(success){
            success(dict);
        }
    } failureResult:^(NSError *error) {
        if(failure){
            failure(error);
        }
    }];
}

- (void)fetchRecordFromTable:(NSString*)table Where:(NSString*)condition
                     success:(void (^)(id dict))success
                     failure:(void (^)(NSError *error))failure{
    NSString *sql = [NSString stringWithFormat:@"select * from %@ where %@;",table,condition];
    [self executeQuery:sql successResult:^(id dict) {
        if(success){
            success(dict);
        }
    } failureResult:^(NSError *error) {
        if(failure){
            failure(error);
        }
    }];
}


#pragma mark - Insert row

- (void)insertRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement{
    NSString *sql = [NSString stringWithFormat:@"insert into %@(",table];
    for(int i=0;i<[statement.fields count];i++){
        if(i==0){
            sql = [sql stringByAppendingFormat:@"%@",[statement.fields objectAtIndex:i]];
        }
        else{
            sql = [sql stringByAppendingFormat:@",%@",[statement.fields objectAtIndex:i]];
        }
        if((i+1)==[statement.fields count]){
            sql = [sql stringByAppendingFormat:@") value("];
        }
    }
    for(int i=0;i<[statement.fields count];i++){
        if(i==0){
            sql = [sql stringByAppendingFormat:@"%@",[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        else{
            sql = [sql stringByAppendingFormat:@",%@",[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        if((i+1)==[statement.fields count]){
            sql = [sql stringByAppendingFormat:@");"];
        }
    }
    [self executeQuery:sql];
}

- (void)insertRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement
                   success:(void (^)(id dict))success
                   failure:(void (^)(NSError *error))failure{
    NSString *sql = [NSString stringWithFormat:@"insert into %@(",table];
    for(int i=0;i<[statement.fields count];i++){
        if(i==0){
            sql = [sql stringByAppendingFormat:@"%@",[statement.fields objectAtIndex:i]];
        }
        else{
            sql = [sql stringByAppendingFormat:@",%@",[statement.fields objectAtIndex:i]];
        }
        if((i+1)==[statement.fields count]){
            sql = [sql stringByAppendingFormat:@") value("];
        }
    }
    for(int i=0;i<[statement.fields count];i++){
        if(i==0){
            sql = [sql stringByAppendingFormat:@"%@",[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        else{
            sql = [sql stringByAppendingFormat:@",%@",[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        if((i+1)==[statement.fields count]){
            sql = [sql stringByAppendingFormat:@");"];
        }
    }
    [self executeQuery:sql successResult:^(id dict) {
        if(success){
            success(dict);
        }
    } failureResult:^(NSError *error) {
        if(failure){
            failure(error);
        }
    }];
}

#pragma mark - Update row

- (void)updateRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement Where:(NSString*)condition{
    NSString *sql = [NSString stringWithFormat:@"update %@ set ",table];
    for(int i=0;i<[statement.fields count];i++){
        if(i==0){
            sql = [sql stringByAppendingFormat:@"%@=%@",[statement.fields objectAtIndex:i],[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        else{
            sql = [sql stringByAppendingFormat:@", %@=%@",[statement.fields objectAtIndex:i],[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        if((i+1)==[statement.fields count]){
            sql = [sql stringByAppendingFormat:@" where %@;",condition];
        }
    }
    [self executeQuery:sql];
}

- (void)updateRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement Where:(NSString*)condition
                   success:(void (^)(id dict))success
                   failure:(void (^)(NSError *error))failure{
    NSString *sql = [NSString stringWithFormat:@"update %@ set ",table];
    for(int i=0;i<[statement.fields count];i++){
        if(i==0){
            sql = [sql stringByAppendingFormat:@"%@=%@",[statement.fields objectAtIndex:i],[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        else{
            sql = [sql stringByAppendingFormat:@", %@=%@",[statement.fields objectAtIndex:i],[statement.dict valueForKey:[statement.fields objectAtIndex:i]]];
        }
        if((i+1)==[statement.fields count]){
            sql = [sql stringByAppendingFormat:@" where %@;",condition];
        }
    }
    [self executeQuery:sql successResult:^(id dict) {
        if(success){
            success(dict);
        }
    } failureResult:^(NSError *error) {
        if(failure){
            failure(error);
        }
    }];
}

#pragma mark - Delete row

- (void)deleteRowFromTable:(NSString*)table Where:(NSString*)condition{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@;",table,condition];
    [self executeQuery:sql];
}

- (void)deleteAllRecordFromTable:(NSString*)table{
    NSString *sql = [NSString stringWithFormat:@"delete from %@;",table];
    [self executeQuery:sql];
}

- (void)deleteRowFromTable:(NSString*)table Where:(NSString*)condition
                   success:(void (^)(id dict))success
                   failure:(void (^)(NSError *error))failure{
    NSString *sql = [NSString stringWithFormat:@"delete from %@ where %@;",table,condition];
    [self executeQuery:sql successResult:^(id dict) {
        if(success){
            success(dict);
        }
    } failureResult:^(NSError *error) {
        if(failure){
            failure(error);
        }
    }];
}

- (void)deleteAllRecordFromTable:(NSString*)table
                         success:(void (^)(id dict))success
                         failure:(void (^)(NSError *error))failure{
    NSString *sql = [NSString stringWithFormat:@"delete from %@;",table];
    [self executeQuery:sql successResult:^(id dict) {
        if(success){
            success(dict);
        }
    } failureResult:^(NSError *error) {
        if(failure){
            failure(error);
        }
    }];
}

@end
