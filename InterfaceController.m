//
//  InterfaceController.m
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "InterfaceController.h"


@implementation InterfaceController

- (id)init
{
	listing = YES;
	lsofData = [[[LSOF alloc] init] retain];
	listing = NO;
	return self;
}

- (IBAction) listFiles:(id)sender
{
	NSString *filter = [filterField stringValue];
	
	[spinner startAnimation:self];
	
	if( [filter length] )
		[lsofData getData:filter];
	else
		[lsofData getData:nil];
	
	[spinner stopAnimation:self];
	
	[outTable reloadData];
	NSLog(@"listing files");
}

-(void)alertDidEnd:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)context
{
	[alert release];
}

- (IBAction) killApplication:(id)sender
{
	int rowIx = [outTable selectedRow];
	pid_t pid;
	
	if( rowIx > 0 )
		pid = [lsofData getPidOfRow:rowIx];
	if( pid > 0 )
	{
		if( kill(pid, SIGQUIT) )
		{
			[[[Alerts alloc] retain] doInfoAlertWithTitle:[[NSString alloc] initWithFormat:@"Error killing process."] infoText:[[NSString alloc] initWithFormat:@"%s", strerror(errno)] forWindow:mainWindow withSelector:@selector(alertDidEnd:returnCode:contextInfo:) withDelegate:self runModal:NO];
		}
	}
}

- (int)numberOfRowsInTableView:(NSTableView *)table
{
	return [lsofData dataCount];
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(int)rowIx
{
	NSString *retVal = nil;
	
	if( col == applicationColumn )
		retVal = [lsofData getField:0 inRow:rowIx];
	else if( col == filePathColumn )
		retVal = [lsofData getField:8 inRow:rowIx];
	
	return retVal;
}

- (Boolean)tableView:(NSTableView *)table shouldEditTableColumn:(NSTableColumn *)col row:(int)row
{
	return NO;
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation
{
	NSString *retVal = [[[NSString alloc] initWithString:@"this is a tool tip"] retain];
	
	return retVal;
}



@end
