//
//  Alerts.m
//  kExpcalc
//
//  Created by Franklin Marmon on 5/13/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "Alerts.h"


@implementation Alerts


-(void) doInfoAlertWithTitle:(NSString *)text infoText:(NSString *)info forWindow:(NSWindow *)window withSelector:(SEL)sel withDelegate:(id)del runModal:(Boolean)modal
{
	NSAlert *alert = [[NSAlert alertWithMessageText:text defaultButton:[NSString stringWithFormat:@"OK"] alternateButton:nil
									   otherButton:nil informativeTextWithFormat:info] retain];
	
	if( modal == NO )
		[alert beginSheetModalForWindow:window modalDelegate:del didEndSelector:sel contextInfo:nil];
	else
		[alert runModal];
}

@end
