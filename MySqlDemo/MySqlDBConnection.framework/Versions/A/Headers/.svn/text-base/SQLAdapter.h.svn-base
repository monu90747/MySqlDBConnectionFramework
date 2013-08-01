//
//  SQLAdapter.h
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "DBAdapter.h"

@protocol SQLConnection;
@protocol SQLDatabase;
@protocol SQLTable;
@protocol SQLField;
@protocol SQLTuple;
@protocol SQLResultSet;

#pragma mark -

@protocol SQLConnection <DBConnection>

- (void)executeSQL:(NSString *)SQL
           success:(void (^)(id <SQLResultSet> resultSet, NSTimeInterval elapsedTime))success
           failure:(void (^)(NSError *error))failure;

- (id <SQLResultSet>)resultSetByExecutingSQL:(NSString *)SQL 
                                       error:(NSError *__autoreleasing *)error;

@property (readonly) NSArray *availableDatabases;

@end

#pragma mark -

@protocol SQLDatabase <DBDatabase>

@property (readonly) id <SQLConnection> connection;

@property (readonly) NSString *name;
@property (readonly) NSStringEncoding stringEncoding;

@property (readonly) NSArray *tables;

- (id)initWithConnection:(id <SQLConnection>)connection 
                    name:(NSString *)name
          stringEncoding:(NSStringEncoding)stringEncoding;

@end

#pragma mark -

@protocol SQLTable <DBDataSource, DBExplorableDataSource, DBQueryableDataSource, DBVisualizableDataSource>

@property (readonly, nonatomic) NSStringEncoding stringEncoding;

- (id)initWithDatabase:(id <SQLDatabase>)database
                  name:(NSString *)name
        stringEncoding:(NSStringEncoding)stringEncoding;

@end

#pragma mark -

@protocol SQLField <NSObject>

@property (readonly, nonatomic) NSUInteger index;
@property (readonly, nonatomic) NSString *name;
@property (readonly, nonatomic) DBValueType type;
@property (readonly, nonatomic) NSUInteger size;

@end

#pragma mark -

@protocol SQLTuple <DBRecord>

@property (readonly, nonatomic) NSUInteger index;

@end

#pragma mark -

@protocol SQLResultSet <DBResultSet>

@property (readonly, nonatomic) NSArray *fields;
@property (readonly, nonatomic) NSArray *tuples;

@end
