//
//  MySqlStatement.h
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface MySqlStatement : NSObject
{
    NSMutableDictionary *dict;
    NSMutableArray *fields;
}
@property(nonatomic,retain) NSMutableDictionary *dict;
@property(nonatomic,retain) NSMutableArray *fields;

- (void)stringValue:(NSString*)value forColumnName:(NSString*)key;
- (void)integerValue:(NSInteger)value forColumnName:(NSString*)key;
@end
