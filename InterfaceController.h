//
//  InterfaceController.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "LSOF.h"
#import "Alerts.h"
#import "Finder.h"

@interface InterfaceController : NSObject {
	IBOutlet NSTextField *filterField;
	IBOutlet NSButton *listButton;
	IBOutlet NSButton *killButton;
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSTableView *outTable;
	IBOutlet NSTableColumn *applicationColumn;
	IBOutlet NSTableColumn *filePathColumn;
	IBOutlet NSTableColumn *fileSizeColumn;
	IBOutlet NSTableColumn *usernameColumn;
	IBOutlet NSToolbar *toobar;
	IBOutlet NSProgressIndicator *probar;
	IBOutlet NSWindow *progSheet;
	IBOutlet NSPopUpButton *volumesBox;
	IBOutlet NSPopUpButton *userButton;
	IBOutlet NSPanel *commentPanel;
	IBOutlet NSPopUpButton *commentType;
	IBOutlet NSTextField *commentSubject;
	IBOutlet NSTextView *commentText;
	IBOutlet NSTextField *commentFrom;

	Boolean listing;
	LSOF *lsofData;
	FinderApplication *theFinder;
	int appColSort;
	int fileSizeSortFlag;
	int filePathSort;
	int usernameSort;
}

- (IBAction) listFiles:(id)sender;
- (IBAction) killApplication:(id)sender;
- (IBAction) openInFinder:(id)sender;
- (IBAction) filterFiles:(id)sender;
- (IBAction) submitComment:(id)sender;
- (IBAction) cancelComment:(id)sender;
- (IBAction) showCommentPane:(id)sender;

// table delegates
- (int)numberOfRowsInTableView:(NSTableView *)table;
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(int)rowIx;
- (Boolean)tableView:(NSTableView *)table shouldEditTableColumn:(NSTableColumn *)col row:(int)row;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
//- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors;
- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

- (void)reloadTable;

// column sorting
- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
- (NSArray *)sortByAppName;

void diskAddCallback( DADiskRef disk, void *context );
void diskRemovedCallback( DADiskRef disk, void *context );
- (void)addVolumeToUI:(NSString *)vol;
- (void)removeVolumeFromUI:(NSString *)vol;
- (void)setupDiskWatcher;

@end
