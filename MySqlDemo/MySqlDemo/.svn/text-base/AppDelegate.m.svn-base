//
//  AppDelegate.m
//  MySqlDemo
//
//  Created by Monu Rathor on 7-10-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//

#import "AppDelegate.h"


#define DATABASE @"msecure"
#define TABLE_Name @"testTable"

@implementation AppDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
	return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    connection = [[MySqlDBConnection alloc]init];
    [connection setDelegate:self];
    [connection connectToMySqlWithScheme:@"mysql"
                                    Host:@"localhost"
                                UserName:@"root"
                                Password:@""
                             DatabseName:DATABASE
                              PortNumber:3306];
    
}

#pragma mark - IBAction method

- (IBAction)clickRun:(id)sender{
    //[connection executeQuery:txtQuery.stringValue];
    
    [connection executeQuery:txtQuery.stringValue successResult:^(id dict) {
        [self showDataInTextView:dict Error:nil];
    } failureResult:^(NSError *error) {
        [self showDataInTextView:nil Error:error];
    }];
}

- (IBAction)clickInsert:(id)sender{
    MySqlStatement *statement = [[MySqlStatement alloc]init];
    [statement stringValue:@"monu rathor" forColumnName:@"name"];
    [statement stringValue:@"Morena" forColumnName:@"address"];
    //[connection insertRowIntoTable:TABLE_Name Statement:statement];
    
    [connection insertRowIntoTable:TABLE_Name Statement:statement success:^(id dict) {
        [self showDataInTextView:dict Error:nil];
    } failure:^(NSError *error) {
        [self showDataInTextView:nil Error:error];
    }];
}

- (IBAction)clickUpdate:(id)sender{
    MySqlStatement *statement = [[MySqlStatement alloc]init];
    [statement stringValue:@"Bhopal" forColumnName:@"address"];
    //[connection updateRowIntoTable:TABLE_Name Statement:statement Where:@"name='monu rathor'"];
    [connection updateRowIntoTable:TABLE_Name Statement:statement Where:@"name='monu rathor'" success:^(id dict) {
        [self showDataInTextView:dict Error:nil];
    } failure:^(NSError *error) {
        [self showDataInTextView:nil Error:error];
    }];
}

- (IBAction)clickDelete:(id)sender{
    //[connection deleteRowFromTable:TABLE_Name Where:@"name='monu rathor'"];
    [connection deleteRowFromTable:TABLE_Name Where:@"name='monu rathor'" success:^(id dict) {
        [self showDataInTextView:dict Error:nil];
    } failure:^(NSError *error) {
        [self showDataInTextView:nil Error:error];
    }];
}

- (IBAction)clickRecord:(id)sender{
    //[connection fetchRecordFromTable:TABLE_Name Where:@"address='Bhopal'"];
    [connection fetchRecordFromTable:TABLE_Name Where:@"address='Bhopal'" success:^(id dict) {
        [self showDataInTextView:dict Error:nil];
    } failure:^(NSError *error) {
        [self showDataInTextView:nil Error:error];
    }];
}

- (IBAction)clickAllRecord:(id)sender{
    //[connection fetchAllRecordFromTable:TABLE_Name];
    [connection fetchAllRecordFromTable:TABLE_Name success:^(id dict) {
        [self showDataInTextView:dict Error:nil];
    } failure:^(NSError *error) {
        [self showDataInTextView:nil Error:error];
    }];
}

- (void)showDataInTextView:(NSDictionary*)dictionary Error:(NSError*)error{
    [txtResult setString:@""];
    if(error){
        [txtResult setString:[NSString stringWithFormat:@"%@",error]];
    }else{
        [txtResult setString:[NSString stringWithFormat:@"%@",dictionary]];
    }
    
}

#pragma mark - MySqlDelegate method

- (void)mySqlConnectionSuccess:(BOOL)successs Error:(NSError *)error{
    if(successs){
        NSLog(@"Connection success");
    }else{
        NSLog(@"Connection fail. Error:%@",error);
    }
}

- (void)mySqlResult:(NSDictionary *)dictionary Error:(NSError *)error{
    [self showDataInTextView:dictionary Error:nil];
}

@end
