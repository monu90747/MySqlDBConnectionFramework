//
//  MySqlStatement.m
//  MySqlSBConnection
//
//  Created by Monu Rathor on 7-8-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//

#import "MySqlStatement.h"

@implementation MySqlStatement
@synthesize dict,fields;

- (id)init{
    self = [super init];
    if(!self){
        return nil;
    }
    dict = [NSMutableDictionary dictionary];
    fields = [[NSMutableArray alloc] init];
    return self;
}

- (void)stringValue:(NSString*)value forColumnName:(NSString*)key{
    [dict setObject:[NSString stringWithFormat:@"'%@'",value] forKey:key];
    [fields addObject:key];
}

- (void)integerValue:(NSInteger)value forColumnName:(NSString*)key{
    [dict setObject:[NSString stringWithFormat:@"%li",(long)value] forKey:key];
    [fields addObject:key];
}

@end
