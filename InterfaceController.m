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
	appColSort = 0;
	fileSizeSortFlag = 0;
	
	[self setupDiskWatcher];
	
	return self;
}

- (void)reloadTable
{
	[outTable reloadData];
}

- (void)setupDiskWatcher
{
	DASessionRef diskSession;
	diskSession = DASessionCreate(kCFAllocatorDefault);
	DARegisterDiskAppearedCallback( diskSession, NULL, diskAddCallback, self );
	DARegisterDiskDisappearedCallback( diskSession, NULL, diskRemovedCallback, self );
	DASessionScheduleWithRunLoop(diskSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode );
}

- (void)awakeFromNib
{
	[volumesBox addItemWithTitle:@"All"];
}

void diskAddCallback( DADiskRef disk, void *context )
{
	CFDictionaryRef dic = DADiskCopyDescription( disk );
	NSString *name = (NSString *)CFDictionaryGetValue( dic, @"DAVolumeName" );
	if( name )
	{
		[(InterfaceController *)context addVolumeToUI:name];
	}
	CFRelease(dic);
}
	
void diskRemovedCallback( DADiskRef disk, void *context )
{
	CFDictionaryRef dic = DADiskCopyDescription( disk );
	NSString *name = (NSString *)CFDictionaryGetValue( dic, @"DAVolumeName" );
	if( name )
	{
		[(InterfaceController *)context removeVolumeFromUI:name];
	}
	CFRelease(dic);
}

- (void)addVolumeToUI:(NSString *)vol
{
	[volumesBox addItemWithTitle:vol];
}

- (void)removeVolumeFromUI:(NSString *)vol
{
	[volumesBox removeItemWithTitle:vol];
}

- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo 
{ 
	[sheet orderOut:self]; 
} 


- (IBAction) listFiles:(id)sender
{
	[probar setUsesThreadedAnimation:YES];	
	[probar startAnimation:self];
	
	[NSApp beginSheet: progSheet
	   modalForWindow: mainWindow
		modalDelegate: self
	   didEndSelector: @selector(progDidEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
	
	[lsofData getData];
	[self filterFiles:self];
	
	[probar stopAnimation:self];
	
	[NSApp endSheet:progSheet];
	[self reloadTable];
}

- (IBAction) filterFiles:(id)sender
{
	NSString *filter = ([[filterField stringValue] length] > 0 ? [filterField stringValue] : nil);
	NSString *vol = [[volumesBox titleOfSelectedItem] copy];
	NSString *volPath = [NSString stringWithFormat:@"/Volumes/%@", vol];
	struct stat st;
	char buf[32];
	
	memset(&st, 0, sizeof(st));
	if( lstat( [volPath UTF8String], &st ) == 0 )
	{
		if( st.st_mode & S_IFLNK )
		{
			memset(buf, 0, 32);
			readlink( [volPath UTF8String], buf, 32 );
			if( strcmp( buf, "/" ) == 0 )
			{
				vol = [NSString stringWithString:@"All"];
			}
		}
	}
		
	
	[lsofData filterDataWithString:filter forVolume:vol];
	[self reloadTable];
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
		pid = [lsofData getPidForRow:rowIx];
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
		retVal = [lsofData getAppNameForRow:rowIx];
	else if( col == filePathColumn )
		retVal = [lsofData getFilePathForRow:rowIx];
	else if( col == fileSizeColumn )
		retVal = [lsofData getFileSizeForRow:rowIx];
	
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
		NSURL *fileUrl = [NSURL fileURLWithPath:[lsofData getFilePathForRow:rowIx]]; 
		FinderItem *theFile = [[theFinder items] objectAtLocation:fileUrl];
		[theFile reveal];
		[theFinder activate];
	}
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:mainWindow];
}

- (NSArray *)sortByAppName
{
	NSArray *descs;
	[outTable setIndicatorImage:nil inTableColumn:fileSizeColumn];
	[outTable setIndicatorImage:nil inTableColumn:filePathColumn];
	fileSizeSortFlag = 0;
	filePathSort = 0;
	switch( appColSort )
	{
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:[lsofData appNameSort], nil ];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:applicationColumn];
			appColSort = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[[lsofData appNameSort] reversedSortDescriptor], nil ];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:applicationColumn];
			appColSort = 2;
			break;
		case 2: // descending -> unsorted
			descs = nil;
			appColSort = 0;
			[outTable setIndicatorImage:nil inTableColumn:applicationColumn];
			break;
	}
	return descs;
}

- (NSArray *)sortByFileSize
{
	NSArray *descs;
	[outTable setIndicatorImage:nil inTableColumn:filePathColumn];
	[outTable setIndicatorImage:nil inTableColumn:applicationColumn];
	filePathSort = 0;
	appColSort = 0;
	switch( fileSizeSortFlag )
	{
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:[lsofData fileSizeSort], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:fileSizeColumn];
			fileSizeSortFlag = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[[lsofData fileSizeSort] reversedSortDescriptor], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:fileSizeColumn];
			fileSizeSortFlag = 2;
			break;
		case 2: // descending -> unsorted
			descs = nil;
			fileSizeSortFlag = 0;
			[outTable setIndicatorImage:nil inTableColumn:fileSizeColumn];
			break;
	}
	return descs;
}

- (NSArray *)sortByFilePath
{
	NSArray *descs;
	[outTable setIndicatorImage:nil inTableColumn:applicationColumn];
	[outTable setIndicatorImage:nil inTableColumn:fileSizeColumn];
	appColSort = 0;
	fileSizeSortFlag = 0;
	switch( filePathSort )
	{
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:[lsofData filePathSort], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:filePathColumn];
			filePathSort = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[[lsofData filePathSort] reversedSortDescriptor], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:filePathColumn];
			filePathSort = 2;
			break;
		case 2: // descending -> unsorted
			descs = nil;
			filePathSort = 0;
			[outTable setIndicatorImage:nil inTableColumn:filePathColumn];
			break;
	}
	return descs;
}

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn
{
	NSArray *descs = nil;
	if( tableColumn == applicationColumn )
	{
		descs = [[self sortByAppName] retain];
	}
	else if( tableColumn == fileSizeColumn )
	{
		descs = [[self sortByFileSize] retain];
	}
	else if( tableColumn == filePathColumn )
	{
		descs = [[self sortByFilePath] retain];
	}
	
	[lsofData sortDataWithDescriptors:descs];
	[self reloadTable];
	if( descs )
		[descs release];
}

@end
