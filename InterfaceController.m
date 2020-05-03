//
//  InterfaceController.m
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 Franklin Marmon. All rights reserved.
//

#import <DiskArbitration/DiskArbitration.h>

#import "InterfaceController.h"

@interface InterfaceController() <NSTableViewDelegate, NSTableViewDataSource, NSMenuDelegate>

@end

@implementation InterfaceController

- (id)init
{
	self = [super init];
	if (self) {
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
	}
	return self;
}

- (void)awakeFromNib
{
	[killButtonItem setEnabled:NO];
	
	[self moveSuperuserEnabledTextToWindowTitle];
	
	bottomInfoLabel.stringValue = @"";
	
	[self updateToolbarButtons];	// this disables the buttons initially
	
	if ([NSUserDefaults.standardUserDefaults boolForKey:@"listAtLaunch"]) {
		[self performSelector:@selector(listFiles:) withObject:nil afterDelay:0];
	}
}

- (void)moveSuperuserEnabledTextToWindowTitle
{
	superuserEnabledVC.layoutAttribute = NSLayoutAttributeRight;
	[mainWindow addTitlebarAccessoryViewController:superuserEnabledVC];
}

- (void)reloadTable
{
	[outTable reloadData];
}

- (void)refreshVolumesBox
{
	[self refreshNSPopUpButton:volumesBox withDict:lsofData.allVolumes sortByCount:NO];
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
	[button.lastItem setTag:-1];
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
			[button.lastItem setTag:[dict.allKeys indexOfObject:name]];
		}
	}
}

- (NSString*)nameOfSelectedItemIn:(NSPopUpButton*)button
{
	NSDictionary *d;
	if (button == volumesBox) {
		d = lsofData.allVolumes;
	} else if (button == usersButton) {
		d = lsofData.allUserNames;
	} else {
		d = lsofData.allProcessNames;
	}
	NSInteger tag = button.selectedTag;
	NSString *name = nil;
	if (tag >= 0) {
		name = d.allKeys[tag];
	}
	return name;
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

	[self refreshVolumesBox];
	[self refreshUserNames];
	[self refreshProcessNames];

	[self filterFiles:self];

	NSArray<NSSortDescriptor*> *descs = outTable.sortDescriptors;
	[lsofData sortDataWithDescriptors:descs];

	[probar stopAnimation:self];

	[NSApp endSheet:progSheet];

	[self reloadTable];
}

- (IBAction)filterFiles:(id)sender
{
	NSString *filter = ([[filterField stringValue] length] > 0 ? [filterField stringValue] : nil);
	NSString *vol = [self nameOfSelectedItemIn:volumesBox];
	NSString *user = [self nameOfSelectedItemIn:usersButton];
	NSString *process = [self nameOfSelectedItemIn:processesButton];
	fileTypes fileType = (fileTypes) [fileTypesButton indexOfSelectedItem];

	[lsofData filterDataWithString:filter forVolume:vol forUser:user forProcess:process forType:fileType];
	
	NSString *info = [NSString stringWithFormat:@"Total: %ld", lsofData.totalCount];
	if (lsofData.totalCount != lsofData.dataCount) {
		info = [info stringByAppendingFormat:@", Shown: %ld", lsofData.dataCount];
	}
	bottomInfoLabel.stringValue = info;
	
	[self reloadTable];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(int)code contextInfo:(void *)context
{
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

/*
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
*/

- (IBAction)openInFinder:(id)sender
{
	NSMutableArray<NSURL*> *urls = [NSMutableArray array];
	
	NSIndexSet *selectedRowIndexes = outTable.selectedRowIndexes;
	[selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
		NSURL *fileUrl = [NSURL fileURLWithPath:[self->lsofData getFilePathForRow:idx]];
		[urls addObject:fileUrl];
	}];

	[NSWorkspace.sharedWorkspace activateFileViewerSelectingURLs:urls];
}

- (void)windowWillClose:(NSNotification *)notification
{
	[NSApp terminate:mainWindow];
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

- (BOOL)loadDocText:(FILE *)man
{
	if (man) {
		[documentTextView setEditable:YES];
		[documentTextView.textStorage beginEditing];
		char buff[1024];
		while (fgets(buff, sizeof(buff), man)) {
			NSString *s = [NSString stringWithCString:buff encoding:NSUTF8StringEncoding];
			NSAttributedString *as = [[NSAttributedString alloc] initWithString:s];
			[documentTextView.textStorage appendAttributedString:as];
		}
		[documentTextView.textStorage endEditing];
		[documentTextView setEditable:NO];
		return YES;
	}
	return NO;
}

- (IBAction)showDocPane:(id)sender
{
	NSInteger row = [outTable selectedRow];
	NSString *an = [lsofData getAppNameForRow:row];

	[documentTextView.textStorage setAttributedString:[[NSAttributedString alloc] init]];

	if (row >= 0) {
		NSString *commandString = [NSString stringWithFormat:@"man %@ | col -b", an];

		FILE *man = popen(commandString.UTF8String, "r");
		[self loadDocText:man];
		fclose(man);

		if (documentTextView.textStorage.length == 0) {
			NSString *s = [NSString stringWithFormat:@"There is no documentation available for %@.", an];
			[documentTextView.textStorage setAttributedString:[[NSAttributedString alloc] initWithString:s]];
		}
		[NSApp beginSheet:documentPanel
			modalForWindow:mainWindow
			 modalDelegate:self
			didEndSelector:@selector(progDidEndSheet:returnCode:contextInfo:)
			   contextInfo:nil];
	} else {
		Alerts *oops = [[Alerts alloc] init];
		[oops doInfoAlertWithTitle:@"Error obtaining documentation."
						  infoText:@"You need to select a row."
						 forWindow:mainWindow
					  withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
					  withDelegate:self
						  runModal:NO];
	}
}

- (void)toolbarWillAddItem:(NSNotification *)note
{
	NSToolbarItem *addedItem = [[note userInfo] objectForKey:@"item"];
	if ([addedItem tag] == kVolumesTag) {
		volumesBox = (NSPopUpButton *)[addedItem view];
	} else if ([addedItem tag] == kUsersTag) {
		usersButton = (NSPopUpButton *)[addedItem view];
	} else if ([addedItem tag] == kProcessesTag) {
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
	} else {
		Alerts *oops = [[Alerts alloc] init];
		[oops doInfoAlertWithTitle:@"Error Googling the application."
						  infoText:@"You need to select a row."
						 forWindow:mainWindow
					  withSelector:@selector(alertDidEnd:returnCode:contextInfo:)
					  withDelegate:self
						  runModal:NO];
	}
}

- (void)updateToolbarButtons
{
	NSIndexSet *selectedRowIndexes = outTable.selectedRowIndexes;

	BOOL hasOne = selectedRowIndexes.count == 1;
	BOOL hasAny = selectedRowIndexes.count > 0;
	NSInteger row = hasOne ? selectedRowIndexes.firstIndex : -1;

	googleLookupButtonItem.enabled = hasOne;
	manLookupButtonItem.enabled = hasOne;
	showInFinderButtonItem.enabled = hasAny;

	BOOL canKill = NO;
	if (hasOne) {
		// Enable Kill button only if process is from current user
		NSString *rowUser = [lsofData getUserForRow:row];
		if (rowUser) {
			struct passwd *pw = getpwnam([rowUser UTF8String]);
			if (pw) {
				uid_t uid = getuid();
				canKill = pw->pw_uid == uid;
			}
		}
	}
	killButtonItem.enabled = canKill;
}


#pragma mark - NSTableViewDelegate, NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)table
{
	return [lsofData dataCount];
}

- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(NSInteger)rowIx
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
	} else if (col == volumeColumn) {
		retVal = [lsofData getVolumeForRow:rowIx];
	}

	return retVal;
}

- (NSString *)tableView:(NSTableView *)aTableView
		 toolTipForCell:(NSCell *)aCell
				   rect:(NSRectPointer)rect
			tableColumn:(NSTableColumn *)aTableColumn
					row:(NSInteger)row
		  mouseLocation:(NSPoint)mouseLocation
{
	NSString *retVal = [NSString stringWithFormat:@"pid: %d", [lsofData getPidForRow:row]];
	return retVal;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateToolbarButtons];
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)TC row:(NSInteger)row
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

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray<NSSortDescriptor *> *)oldDescriptors
{
	NSArray<NSSortDescriptor*> *descs = tableView.sortDescriptors;
	[lsofData sortDataWithDescriptors:descs];
	[self reloadTable];
}

#pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu*)menu
{
	// Here we can re-sort the popup menus as needed (ticket #3)
	
	//	if (menu == self.listModeTableView.menu) {
	//	} else if (menu == self.openWithMenuItem.submenu || [menu.identifier isEqualToString:@"appMenuOpenWithMenu"]) {
	//	}
}

@end
