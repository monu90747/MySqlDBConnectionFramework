//
//  MySqlDBConnection.h
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MySQLAdapter.h"
#import "DBAdapter.h"
#import "SQLAdapter.h"
#import "MySqlStatement.h"

@protocol MySqlDelegate<NSObject>
/*
 * It is return result for all query.
 * It is called when you call executeQuery:, fetchAllRecordFromTable:, fetchRecordFromTable:Where:,
 * insertRowIntoTable:Statement:, updateRowIntoTable:Statement:Where:, deleteRowFromTable:Where: method.
 */
- (void)mySqlResult:(NSDictionary*)dictionary Error:(NSError*)error;

/*
 * When connection is succesfully established then mySqlConnectionSuccess:Error: method is called.
 */
- (void)mySqlConnectionSuccess:(BOOL)successs Error:(NSError*)error;
@end

@interface MySqlDBConnection : NSObject
{
    NSURL *connectionURL;
    BOOL isConnecting;
    BOOL connecting;
    id<MySqlDelegate> delegate;
}
@property (weak,nonatomic) id<MySqlDelegate> delegate;
@property (readwrite, nonatomic, getter = isConnecting) BOOL connecting;
@property (strong) NSURL *connectionURL;
@property (readonly) BOOL isConnecting;

/*
 * This method is used for established a connection.
 * Given port number 3306 for mysql. It i default port number for myql.
 */
- (void)connectToMySqlWithScheme:(NSString*)scheme Host:(NSString*)host UserName:(NSString*)user Password:(NSString*)password DatabseName:(NSString*)database PortNumber:(int)portNo;

- (void)connectToMySqlWithScheme:(NSString*)scheme
                            Host:(NSString*)host
                        UserName:(NSString*)user
                        Password:(NSString*)password
                     DatabseName:(NSString*)database
                      PortNumber:(int)portNo
                   successResult:(void (^)(id <DBConnection> connection, id connectionUR))successResult
                   failureResult:(void (^)(NSError *error))failureResult;
/*
 * This method is used for execute sql query.
 * The result return in mySqlResult:Error: delegate method.
 */
- (void)executeQuery:(NSString*)sql;
- (void)executeQuery:(NSString *)sql
     successResult:(void (^)(id dict))successResult
     failureResult:(void (^)(NSError *error))failureResult;

/*
 * Fetch record from teble.
 */
- (void)fetchAllRecordFromTable:(NSString*)table;
- (void)fetchRecordFromTable:(NSString*)table Where:(NSString*)condition;

- (void)fetchAllRecordFromTable:(NSString *)table
                        success:(void (^)(id dict))success
                        failure:(void (^)(NSError *error))failure;
- (void)fetchRecordFromTable:(NSString*)table Where:(NSString*)condition
                     success:(void (^)(id dict))success
                     failure:(void (^)(NSError *error))failure;

/*
 * Method for using insert row into table.
 * Statement is used for column name and its value.
 */
- (void)insertRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement;

- (void)insertRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement
                   success:(void (^)(id dict))success
                   failure:(void (^)(NSError *error))failure;
/*
 * Method for using update row into table.
 * Statement is used for column name and its value.
 */
- (void)updateRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement Where:(NSString*)condition;

- (void)updateRowIntoTable:(NSString*)table Statement:(MySqlStatement*)statement Where:(NSString*)condition
                   success:(void (^)(id dict))success
                   failure:(void (^)(NSError *error))failure;

/*
 * This method is used for delete row.
 */
- (void)deleteRowFromTable:(NSString*)table Where:(NSString*)condition;
- (void)deleteAllRecordFromTable:(NSString*)table;

- (void)deleteRowFromTable:(NSString*)table Where:(NSString*)condition
                   success:(void (^)(id dict))success
                   failure:(void (^)(NSError *error))failure;
- (void)deleteAllRecordFromTable:(NSString*)table
                         success:(void (^)(id dict))success
                         failure:(void (^)(NSError *error))failure;

@end
