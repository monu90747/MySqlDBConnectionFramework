//
//  AppDelegate.h
//  MySqlDemo
//
//  Created by Monu Rathor on 7-10-13.
//  Copyright (c) 2013 Hunka Technologies Pvt. Ltd. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MySqlDBConnection/MySqlDBConnection.h>

@interface AppDelegate : NSObject <NSApplicationDelegate,MySqlDelegate>
{
    MySqlDBConnection *connection;
    IBOutlet NSTextField *txtQuery;
    IBOutlet NSTextView *txtResult;
}

@property (assign) IBOutlet NSWindow *window;

- (IBAction)clickRun:(id)sender;
- (IBAction)clickInsert:(id)sender;
- (IBAction)clickUpdate:(id)sender;
- (IBAction)clickDelete:(id)sender;
- (IBAction)clickRecord:(id)sender;
- (IBAction)clickAllRecord:(id)sender;

@end
