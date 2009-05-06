//
//  InterfaceController.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sys/types.h>
#import <pwd.h>
#import "LSOF.h"
#import "Alerts.h"
#import "Finder.h"

#define kVolumesTag 100
#define kUsersTag   200

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
	IBOutlet NSTableColumn *cputimeColumn;
	IBOutlet NSToolbar *toobar;
	IBOutlet NSProgressIndicator *probar;
	IBOutlet NSWindow *progSheet;
	IBOutlet NSPopUpButton *volumesBox;
	IBOutlet NSPopUpButton *userButton;
	IBOutlet NSPanel *commentPanel;
	IBOutlet NSPanel *documentPanel;
	IBOutlet NSPopUpButton *commentType;
	IBOutlet NSPopUpButton *fileTypesButton;
	IBOutlet NSTextField *commentSubject;
	IBOutlet NSTextView *commentText;
	IBOutlet NSTextField *commentFrom;
	IBOutlet NSToolbarItem *killButtonItem;
	IBOutlet NSToolbarItem *userButtonItem;
	IBOutlet NSTextView *documentTextView;
	IBOutlet NSTextField *progressText;

	Boolean listing;
	LSOF *lsofData;
	FinderApplication *theFinder;
	int appColSort;
	int fileSizeSortFlag;
	int filePathSort;
	int usernameSort;
	int cpusort;
}

- (IBAction) listFiles:(id)sender;
- (IBAction) killApplication:(id)sender;
- (IBAction) openInFinder:(id)sender;
- (IBAction) filterFiles:(id)sender;
- (IBAction) submitComment:(id)sender;
- (IBAction) cancelComment:(id)sender;
- (IBAction) showCommentPane:(id)sender;
- (IBAction) showDocPane:(id)sender;
- (IBAction) dismissDoc:(id)sender;
- (IBAction) googleAppName:(id)sender;

// table delegates
- (int)numberOfRowsInTableView:(NSTableView *)table;
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(int)rowIx;
- (Boolean)tableView:(NSTableView *)table shouldEditTableColumn:(NSTableColumn *)col row:(int)row;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (Boolean)tableView:(NSTableView *)table shouldSelectRow:(NSInteger)row;
- (void) toolbarWillAddItem:(NSNotification *)note;
- (void)tableView: (NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)TC row:(int)row;

- (void)reloadTable;

// column sorting
- (void)tableView:(NSTableView *)tableView mouseDownInHeaderOfTableColumn:(NSTableColumn *)tableColumn;
- (NSArray *)sortByAppName;

void diskAddCallback( DADiskRef disk, void *context );
void diskRemovedCallback( DADiskRef disk, void *context );
- (void)addVolumeToUI:(NSString *)vol;
- (void)removeVolumeFromUI:(NSString *)vol;
- (void)setupDiskWatcher;
- (NSString *)formatCpuTime:(int)secs;

@end
