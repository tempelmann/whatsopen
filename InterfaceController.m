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
	theFinder = [SBApplication applicationWithBundleIdentifier: @"com.apple.finder"];
	listing = YES;
	lsofData = [[[LSOF alloc] init] retain];
	listing = NO;
	return self;
}

- (void)awakeFromNib
{
	[self addVolumesToUI];
}

- (void)addVolumesToUI
{
	NSArray *items = [[NSFileManager defaultManager] directoryContentsAtPath:[NSString stringWithFormat:@"/Volumes"]];
	NSString *i;
	
	for( i in items )
	{
		[volumesBox addItemWithTitle:i];
	}
}

- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo 
{ 
	[sheet orderOut:self]; 
} 


- (IBAction) listFiles:(id)sender
{
	NSString *filter = [filterField stringValue];
	NSString *vol = [NSString stringWithFormat:@"\"%@\"", [volumesBox titleOfSelectedItem]];
	
	[probar setUsesThreadedAnimation:YES];
	
	[probar startAnimation:self];
	
	[NSApp beginSheet: progSheet
	   modalForWindow: mainWindow
		modalDelegate: self
	   didEndSelector: @selector(progDidEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	
	if( [filter length] )
		[lsofData getData:filter forVolume:vol];
	else
		[lsofData getData:nil forVolume:vol];
	
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
		NSURL *fileUrl = [NSURL fileURLWithPath:[lsofData getFileOfRow:rowIx]]; 
		FinderItem *theFile = [[theFinder items] objectAtLocation:fileUrl];
		[theFile reveal];
		[theFinder activate];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:mainWindow];
}

@end
