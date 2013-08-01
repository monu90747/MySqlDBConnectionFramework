//
//  MySQLAdapter.h
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SQLAdapter.h"

extern NSString * const MySQLErrorDomain;

@interface MySQLAdapter : NSObject <DBAdapter>
@end

#pragma mark -

@interface MySQLConnection : NSObject <SQLConnection>
@end

#pragma mark -

@interface MySQLDatabase : NSObject <SQLDatabase>
@end

#pragma mark -

@interface MySQLTable : NSObject <SQLTable>
@end

#pragma mark -

@interface MySQLField : NSObject <SQLField>

+ (MySQLField *)fieldInMySQLResult:(void *)result 
                           atIndex:(NSUInteger)fieldIndex;

- (id)objectForBytes:(const char *)bytes 
              length:(NSUInteger)length 
            encoding:(NSStringEncoding)encoding;

@end

#pragma mark -

@interface MySQLTuple : NSObject <SQLTuple>

- (id)initWithValuesKeyedByFieldName:(NSDictionary *)keyedValues;

@end

#pragma mark -

@interface MySQLResultSet : NSObject <SQLResultSet>

- (id)initWithMySQLResult:(void *)result;

@end
