//
//  AppDelegate.m
//  WhatsOpen
//
//  Created by Thomas Tempelmann on 01.05.20.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
	NSColor *bgColor = [NSColor colorWithRed:1 green:1 blue:0.6 alpha:1];
	[NSUserDefaults.standardUserDefaults registerDefaults:@{
		@"ipv4HilightColor": [NSArchiver archivedDataWithRootObject:bgColor]
	}];
}

@end
