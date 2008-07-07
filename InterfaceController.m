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

- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo 
{ 
	[sheet orderOut:self]; 
} 


- (IBAction) listFiles:(id)sender
{
	NSString *filter = [filterField stringValue];
	
	[probar setUsesThreadedAnimation:YES];
	
	[probar startAnimation:self];
	
	[NSApp beginSheet: progSheet
	   modalForWindow: mainWindow
		modalDelegate: self
	   didEndSelector: @selector(progDidEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	
	if( [filter length] )
		[lsofData getData:filter];
	else
		[lsofData getData:nil];
	
	[probar stopAnimation:self];
	
	[NSApp endSheet:progSheet];
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
	else if( col == fileSizeColumn )
		retVal = [lsofData getField:9 inRow:rowIx];
	
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

- (IBAction) openInFinder:(id)sender
{
	int rowIx = [outTable selectedRow];
	if( rowIx >= 0 )
	{
		NSString *path = [[lsofData getFileOfRow:rowIx] copy];
		char *upath = malloc([path length]);
		if( upath )
		{
			strcpy(upath, [path UTF8String]);
			char *p;
			for( p = &upath[strlen(upath)-1]; p >= upath && *p != '/'; p-- ) *p = 0;
			if( strlen(upath) )
			{
				char cmd[512];
				sprintf(cmd, "open %s", upath);
				system(cmd);
			}

			free(upath);
		}
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:mainWindow];
}

@end
