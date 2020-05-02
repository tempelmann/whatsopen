//
//  InterfaceController.m
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 Franklin Marmon. All rights reserved.
//

#import <DiskArbitration/DiskArbitration.h>

#import "InterfaceController.h"

@interface InterfaceController()
	@property NSMutableSet<NSString*> *volumeNames;
@end

@implementation InterfaceController

- (id)init
{
	self = [super init];
	if (self) {
		//theFinder = [SBApplication applicationWithBundleIdentifier:@"com.apple.finder"];
		listing = YES;
		lsofData = [[LSOF alloc] init];
		[lsofData bind:@"alternateColor"
			   toObject:[NSUserDefaultsController sharedUserDefaultsController]
			withKeyPath:@"values.alternateHilightColor"
				options:[NSDictionary dictionaryWithObject:NSUnarchiveFromDataTransformerName
													forKey:NSValueTransformerNameBindingOption]];
		listing = NO;
		appColSort = 0;
		fileSizeSortFlag = 0;
		usernameSort = 0;

		[self setupDiskWatcher];
	}
	return self;
}

- (void)awakeFromNib
{
	[killButtonItem setEnabled:NO];
	
	#if 1
		// Always list at start
		[self performSelector:@selector(listFiles:) withObject:nil afterDelay:0];
	#endif
}

- (void)reloadTable
{
	[outTable reloadData];
}

- (void)setupDiskWatcher
{
	self.volumeNames = [NSMutableSet set];
	DASessionRef diskSession;
	diskSession = DASessionCreate(kCFAllocatorDefault);
	DARegisterDiskAppearedCallback(diskSession, NULL, diskAddCallback, (__bridge void *_Nullable)(self));
	DARegisterDiskDisappearedCallback(diskSession, NULL, diskRemovedCallback, (__bridge void *_Nullable)(self));
	DASessionScheduleWithRunLoop(diskSession, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
}

static void diskAddCallback(DADiskRef disk, void *context)
{
	CFDictionaryRef dic = DADiskCopyDescription(disk);
	NSString *name = (NSString *)CFDictionaryGetValue(dic, @"DAVolumeName");
	if (name) {
		[(__bridge InterfaceController *)context addVolume:name];
	}
	CFRelease(dic);
}

static void diskRemovedCallback(DADiskRef disk, void *context)
{
	CFDictionaryRef dic = DADiskCopyDescription(disk);
	NSString *name = (NSString *)CFDictionaryGetValue(dic, @"DAVolumeName");
	if (name) {
		[(__bridge InterfaceController *)context removeVolume:name];
	}
	CFRelease(dic);
}

- (void)addVolume:(NSString *)vol
{
	[self.volumeNames addObject:vol];
	[self refreshVolumesBox];
}

- (void)removeVolume:(NSString *)vol
{
	[self.volumeNames removeObject:vol];
	[self refreshVolumesBox];
}

- (void)refreshVolumesBox
{
	[self refreshNSPopUpButton:volumesBox withTitles:self.volumeNames.allObjects];
}

- (void)refreshUserNames
{
	[self refreshNSPopUpButton:usersButton withDict:lsofData.allUserNames sortByCount:NO];
}

- (void)refreshProcessNames
{
	[self refreshNSPopUpButton:processesButton withDict:lsofData.allProcessNames sortByCount:YES];
}

- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:self];
}

- (void)refreshNSPopUpButton:(NSPopUpButton*)button withDict:(NSDictionary<NSString*,NSNumber*>*)dict sortByCount:(BOOL)sortByCount
{
	[button removeAllItems];
	[button addItemWithTitle:@"All"];	// so that "All" always appears first
	if (dict.count > 0) {
		NSArray<NSString*> *names;
		if (sortByCount) {
		 	names = [dict.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString* _Nonnull name1, NSString* _Nonnull name2) {
		 		NSInteger v1 = dict[name1].integerValue;
		 		NSInteger v2 = dict[name2].integerValue;
		 		if (v1 > v2) {
		 			return NSOrderedAscending;
				} else if (v1 < v2) {
    				return NSOrderedDescending;
    			}
    			return NSOrderedSame;
			}];
		} else {
			// sort by name
		 	names = [dict.allKeys sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
		}
		for (NSString *name in names) {
			[button addItemWithTitle:[NSString stringWithFormat:@"%@ (%@)", name, dict[name]]];
			//[button.lastItem setTag:<#(NSInteger)#>]
		}
	}
}

- (void)refreshNSPopUpButton:(NSPopUpButton*)button withTitles:(NSArray<NSString*>*)titles
{
	[button removeAllItems];
	[button addItemWithTitle:@"All"];	// so that "All" always appears first
	if (titles.count > 0) {
		[button addItemsWithTitles:[titles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	}
}

- (IBAction)listFiles:(id)sender
{
	[probar setUsesThreadedAnimation:YES];
	[probar startAnimation:self];

	[NSApp beginSheet:progSheet
		modalForWindow:mainWindow
		 modalDelegate:self
		didEndSelector:@selector(progDidEndSheet:returnCode:contextInfo:)
		   contextInfo:nil];

	if (NOT [lsofData getData:progressText]) {
		NSBeep();
	}

	[self refreshUserNames];
	[self refreshProcessNames];
	[self filterFiles:self];

	[probar stopAnimation:self];

	[NSApp endSheet:progSheet];
	[self reloadTable];
}

- (IBAction)filterFiles:(id)sender
{
	NSString *filter = ([[filterField stringValue] length] > 0 ? [filterField stringValue] : nil);
	NSString *vol = [[volumesBox titleOfSelectedItem] copy];
	NSString *volPath = [NSString stringWithFormat:@"/Volumes/%@", vol];
	NSString *user = [NSString stringWithString:[usersButton titleOfSelectedItem]];
	NSString *process = [NSString stringWithString:[processesButton titleOfSelectedItem]];
	fileTypes fileType = (fileTypes) [fileTypesButton indexOfSelectedItem];
	struct stat st;
	char buf[32];

	memset(&st, 0, sizeof(st));
	if (lstat([volPath UTF8String], &st) == 0) {
		if (st.st_mode & S_IFLNK) {
			memset(buf, 0, 32);
			readlink([volPath UTF8String], buf, 32);
			if (strcmp(buf, "/") == 0) {
				vol = @"All";
			}
		}
	}

	[lsofData filterDataWithString:filter forVolume:vol forUser:user forProcess:process forType:fileType];
	[self reloadTable];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)context
{
	//[alert release];
}

- (void)killAlertDidEnd:(NSAlert *)alert resultCode:(int)resultCode contextInfo:(void *)context
{
	if (resultCode == NSAlertDefaultReturn) {
		NSInteger rowIx = [outTable selectedRow];
		if (rowIx >= 0) {
			pid_t pid = [lsofData getPidForRow:rowIx];
			if (pid >= 0) {
				if (kill(pid, SIGQUIT)) {
					[[Alerts alloc] doInfoAlertWithTitle:[[NSString alloc] initWithFormat:@"Error killing process."]
												infoText:[[NSString alloc] initWithFormat:@"%s", strerror(errno)]
											   forWindow:mainWindow
											withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
											withDelegate:self
												runModal:NO];
				}
			}
		}
	}
	else if (resultCode == NSAlertAlternateReturn) {
		[[alert window] orderOut:self];
		[self showDocPane:self];
	}
}

- (IBAction)killApplication:(id)sender
{
	NSInteger rowIx = [outTable selectedRow];
	if (rowIx >= 0) {
		Alerts *killAlert = [[Alerts alloc] init];
		NSString *title =
			[NSString stringWithFormat:@"Are you sure you want to kill '%@'?", [lsofData getAppNameForRow:rowIx]];
		[killAlert setAltButton:@"App Docs"];
		[killAlert setOtherButton:@"Cancel"];
		[killAlert doInfoAlertWithTitle:title
							   infoText:@"No data will be saved in the application."
							  forWindow:mainWindow
						   withSelector:@selector(killAlertDidEnd:resultCode:contextInfo:)
						   withDelegate:self
							   runModal:NO];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)table
{
	return [lsofData dataCount];
}

- (NSString *)formatCpuTime:(NSInteger)secs
{
	NSInteger mins, hours, days;
	mins = hours = days = 0;
	if (secs > 86400) {
		days = (secs / 86400);
		secs -= days * 86400;
	}
	if (secs > 3600) {
		hours = (secs / 3600);
		secs -= (hours * 3600);
	}
	if (secs > 60) {
		mins = (secs / 60);
		secs -= (mins * 60);
	}
	return [NSString stringWithFormat:@"%ld.%ld:%ld:%ld", (long)days, (long)hours, (long)mins, (long)secs];
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(int)rowIx
{
	NSString *retVal = nil;

	if (col == applicationColumn) {
		retVal = [lsofData getAppNameForRow:rowIx];
	} else if (col == filePathColumn) {
		retVal = [lsofData getFilePathForRow:rowIx];
	} else if (col == fileSizeColumn) {
		retVal = [lsofData getFileSizeForRow:rowIx];
	} else if (col == usernameColumn) {
		retVal = [lsofData getUserForRow:rowIx];
	//} else if (col == cputimeColumn) {
	//	retVal = [self formatCpuTime:[lsofData getCpuTimeForRow:rowIx]];
	}

	return retVal;
}

- (Boolean)tableView:(NSTableView *)table shouldEditTableColumn:(NSTableColumn *)col row:(int)row
{
	return NO;
}

- (NSString *)tableView:(NSTableView *)aTableView
		 toolTipForCell:(NSCell *)aCell
				   rect:(NSRectPointer)rect
			tableColumn:(NSTableColumn *)aTableColumn
					row:(NSInteger)row
		  mouseLocation:(NSPoint)mouseLocation
{
	NSString *retVal = [NSString stringWithFormat:@"pid:%d", [lsofData getPidForRow:row]];
/*
	Boolean isSet;
	if (aTableColumn == cputimeColumn) {
		retVal = [retVal stringByAppendingString:@"\nFormat: days.hours:minutes:seconds"];
		if (CFPreferencesGetAppBooleanValue(CFSTR("lsofFullList"), kCFPreferencesCurrentApplication, &isSet) == NO)
			retVal = [retVal stringByAppendingString:@"\nCPU Time Disabled (turn on root to enable)"];
	}
*/
	return retVal;
}

- (IBAction)openInFinder:(id)sender
{
	NSInteger rowIx = [outTable selectedRow];
	if (rowIx >= 0) {
		NSURL *fileUrl = [NSURL fileURLWithPath:[lsofData getFilePathForRow:rowIx]];
		#if 1
			[NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:@[fileUrl]];
		#else
			SBElementArray *items = [theFinder items];
			FinderItem *theFile = [items objectAtLocation:fileUrl];
			if (theFile) {
				[theFile reveal];
				[theFinder activate];
			} else {
				NSBeep();
			}
		#endif
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
	[outTable setIndicatorImage:nil inTableColumn:usernameColumn];
	//[outTable setIndicatorImage:nil inTableColumn:cputimeColumn];
	usernameSort = 0;
	fileSizeSortFlag = 0;
	filePathSort = 0;
	cpusort = 0;
	switch (appColSort) {
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:lsofData.processNameSortDesc, nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"]
						  inTableColumn:applicationColumn];
			appColSort = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[lsofData.processNameSortDesc reversedSortDescriptor], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"]
						  inTableColumn:applicationColumn];
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
	[outTable setIndicatorImage:nil inTableColumn:usernameColumn];
	//[outTable setIndicatorImage:nil inTableColumn:cputimeColumn];
	usernameSort = 0;
	filePathSort = 0;
	appColSort = 0;
	cpusort = 0;
	switch (fileSizeSortFlag) {
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:lsofData.fileSizeSortDesc, nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:fileSizeColumn];
			fileSizeSortFlag = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[lsofData.fileSizeSortDesc reversedSortDescriptor], nil];
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
	[outTable setIndicatorImage:nil inTableColumn:usernameColumn];
	//[outTable setIndicatorImage:nil inTableColumn:cputimeColumn];
	usernameSort = 0;
	appColSort = 0;
	fileSizeSortFlag = 0;
	cpusort = 0;
	switch (filePathSort) {
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:lsofData.filePathSortDesc, nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:filePathColumn];
			filePathSort = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[lsofData.filePathSortDesc reversedSortDescriptor], nil];
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

- (NSArray *)sortByUserName
{
	NSArray *descs;
	[outTable setIndicatorImage:nil inTableColumn:applicationColumn];
	[outTable setIndicatorImage:nil inTableColumn:fileSizeColumn];
	[outTable setIndicatorImage:nil inTableColumn:filePathColumn];
	//[outTable setIndicatorImage:nil inTableColumn:cputimeColumn];
	fileSizeSortFlag = 0;
	filePathSort = 0;
	appColSort = 0;
	cpusort = 0;
	switch (usernameSort) {
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:lsofData.usernameSortDesc, nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:usernameColumn];
			usernameSort = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[lsofData.usernameSortDesc reversedSortDescriptor], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:usernameColumn];
			usernameSort = 2;
			break;
		case 2: // descending -> unsorted
			descs = nil;
			usernameSort = 0;
			[outTable setIndicatorImage:nil inTableColumn:usernameColumn];
			break;
	}
	return descs;
}

/*
- (NSArray *)sortByCPU
{
	NSArray *descs;
	[outTable setIndicatorImage:nil inTableColumn:applicationColumn];
	[outTable setIndicatorImage:nil inTableColumn:fileSizeColumn];
	[outTable setIndicatorImage:nil inTableColumn:filePathColumn];
	fileSizeSortFlag = 0;
	filePathSort = 0;
	appColSort = 0;
	switch (cpusort) {
		case 0: // unsorted -> ascending
			descs = [NSArray arrayWithObjects:[lsofData cpuSort], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSAscendingSortIndicator"] inTableColumn:cputimeColumn];
			cpusort = 1;
			break;
		case 1: // ascending -> descending
			descs = [NSArray arrayWithObjects:[[lsofData cpuSort] reversedSortDescriptor], nil];
			[outTable setIndicatorImage:[NSImage imageNamed:@"NSDescendingSortIndicator"] inTableColumn:cputimeColumn];
			cpusort = 2;
			break;
		case 2: // descending -> unsorted
			descs = nil;
			cpusort = 0;
			[outTable setIndicatorImage:nil inTableColumn:cputimeColumn];
			break;
	}
	return descs;
}
*/

- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn
{
	NSArray *descs = nil;
	if (tableColumn == applicationColumn) {
		descs = [self sortByAppName];
	}
	else if (tableColumn == fileSizeColumn) {
		descs = [self sortByFileSize];
	}
	else if (tableColumn == filePathColumn) {
		descs = [self sortByFilePath];
	}
	else if (tableColumn == usernameColumn) {
		descs = [self sortByUserName];
	}
	//else if (tableColumn == cputimeColumn) {
	//	descs = [self sortByCPU];
	//}

	[lsofData sortDataWithDescriptors:descs];
	[self reloadTable];
}

- (IBAction)submitComment:(id)sender
{
	NSLog(@"submit comment");
	NSURL *url = [NSURL URLWithString:@"http://www.agasupport.com/programComment.php"];
	NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
	NSString *stringBoundary = @"0xKhTmLbOuNdArY";
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", stringBoundary];
	[urlRequest addValue:contentType forHTTPHeaderField:@"Content-Type"];
	Alerts *resAlert = [[Alerts alloc] init];

	[urlRequest setHTTPMethod:@"POST"];
	NSMutableString *postData = [[NSMutableString alloc] init];
	[postData
		appendString:[NSString stringWithFormat:@"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
												stringBoundary, @"programname", @"whatsopen"]];
	[postData appendString:[NSMutableString
							   stringWithFormat:@"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
												stringBoundary, @"subject", [commentSubject stringValue]]];
	[postData appendString:[NSMutableString
							   stringWithFormat:@"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
												stringBoundary, @"type", [commentType titleOfSelectedItem]]];
	[postData appendString:[NSMutableString
							   stringWithFormat:@"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
												stringBoundary, @"from", [commentFrom stringValue]]];
	[postData appendString:[NSMutableString
							   stringWithFormat:@"\r\n--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n%@",
												stringBoundary, @"text", [[commentText textStorage] string]]];
	[postData appendString:[NSString stringWithFormat:@"\r\n--%@", stringBoundary]];

	[urlRequest setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
	NSURLConnection *connectionResponse = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
	if (!connectionResponse) {
		NSLog(@"failed to submit request");
		[resAlert doInfoAlertWithTitle:@"I'm sorry, your message couldn't be sent."
							  infoText:@"http submission failed"
							 forWindow:mainWindow
						  withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						  withDelegate:self
							  runModal:NO];
	}
	else {
		[NSApp endSheet:commentPanel];
		[commentFrom setStringValue:@"your@email.dom"];
		[commentSubject setStringValue:@"Your Subject"];
		[[commentText textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:@""]];
		[resAlert doInfoAlertWithTitle:@"Your message has been sent."
							  infoText:@"Thank you for using WhatsOpen!"
							 forWindow:mainWindow
						  withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						  withDelegate:self
							  runModal:NO];
	}
}

- (IBAction)cancelComment:(id)sender
{
	[NSApp endSheet:commentPanel];
}

- (IBAction)dismissDoc:(id)sender
{
	[NSApp endSheet:documentPanel];
}

- (IBAction)showCommentPane:(id)sender
{
	[NSApp beginSheet:commentPanel
		modalForWindow:mainWindow
		 modalDelegate:self
		didEndSelector:@selector(progDidEndSheet:returnCode:contextInfo:)
		   contextInfo:nil];
}

- (void)loadDocText:(FILE *)man
{
	char buff[1024];

	if (man) {
		[documentTextView setEditable:YES];
		[[documentTextView textStorage] beginEditing];
		while (fgets(buff, 1024, man)) {
			[[documentTextView textStorage]
				appendAttributedString:[[NSAttributedString alloc]
										   initWithString:[NSString stringWithFormat:@"%s", buff]]];
		}
		[[documentTextView textStorage] endEditing];
		[documentTextView setEditable:NO];
	}
}

- (IBAction)showDocPane:(id)sender
{
	NSInteger row = [outTable selectedRow];
	NSString *an = [lsofData getAppNameForRow:row];

	[[documentTextView textStorage] setAttributedString:[[NSAttributedString alloc] init]];

	if (row >= 0) {
		NSString *commandString = [NSString stringWithFormat:@"man %@ | col -b", an];

		FILE *man = popen([commandString UTF8String], "r");
		[self loadDocText:man];
		fclose(man);

		if ([[documentTextView textStorage] length] == 0)
			[[documentTextView textStorage]
				setAttributedString:
					[[NSAttributedString alloc]
						initWithString:[NSString stringWithFormat:@"There is no documentation available for %@.", an]]];

		[NSApp beginSheet:documentPanel
			modalForWindow:mainWindow
			 modalDelegate:self
			didEndSelector:@selector(progDidEndSheet:returnCode:contextInfo:)
			   contextInfo:nil];
	}
	else {
		Alerts *oops = [[Alerts alloc] init];
		[oops doInfoAlertWithTitle:@"Error obtaining documentation."
						  infoText:@"You need to select a row."
						 forWindow:mainWindow
					  withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
					  withDelegate:self
						  runModal:NO];
	}
}

- (Boolean)tableView:(NSTableView *)table shouldSelectRow:(NSInteger)row
{
	NSString *rowUser = [lsofData getUserForRow:row];
	struct passwd *pw = NULL;
	uid_t uid = getuid();

	if (rowUser) {
		pw = getpwnam([rowUser UTF8String]);
		if (pw) {
			if (pw->pw_uid == uid) {
				[killButtonItem setEnabled:YES];
			}
			else {
				[killButtonItem setEnabled:NO];
			}
		}
	}

	return YES;
}

- (void)toolbarWillAddItem:(NSNotification *)note
{
	NSToolbarItem *addedItem = [[note userInfo] objectForKey:@"item"];
	if ([addedItem tag] == kVolumesTag) {
		volumesBox = (NSPopUpButton *)[addedItem view];
	}
	else if ([addedItem tag] == kUsersTag) {
		usersButton = (NSPopUpButton *)[addedItem view];
	}
	else if ([addedItem tag] == kProcessesTag) {
		processesButton = (NSPopUpButton *)[addedItem view];
	}
}

- (IBAction)googleAppName:(id)sender
{
	NSInteger row = [outTable selectedRow];
	if (row >= 0) {
		NSString *an = [lsofData getAppNameForRow:row];
		NSString *url = [NSString stringWithFormat:@"http://www.google.com/search?q=macos+%@", an];
		[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
		[self dismissDoc:self];
	}
	else {
		Alerts *oops = [[Alerts alloc] init];
		[oops doInfoAlertWithTitle:@"Error Googling the application."
						  infoText:@"You need to select a row."
						 forWindow:mainWindow
					  withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
					  withDelegate:self
						  runModal:NO];
	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)TC row:(int)row
{
	fileTypes type = [lsofData getFileTypeForRow:row];
	NSColor *color = [lsofData alternateColor];

	switch (type) {
		case RegularFile:
			[aCell setDrawsBackground:NO];
			[aCell setBackgroundColor:[NSColor whiteColor]];
			break;
		default:
			[aCell setDrawsBackground:YES];
			[aCell setBackgroundColor:color];
			break;
	}
}

@end
