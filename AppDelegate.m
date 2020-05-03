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
	NSColor *bgColor = [NSColor colorWithRed:1 green:1 blue:0.8 alpha:1];
	[NSUserDefaults.standardUserDefaults registerDefaults:@{
		@"alternateHilightColor": [NSArchiver archivedDataWithRootObject:bgColor],
		@"listAtLaunch": @NO,
		@"lsofFullList": @NO
	}];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	//NSLog (@"%s", __func__);
	return;
}

@end
