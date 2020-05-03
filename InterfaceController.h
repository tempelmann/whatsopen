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
#import "ScriptableFinder.h"

#define kVolumesTag 100
#define kUsersTag   200
#define kProcessesTag   300

@interface InterfaceController : NSObject {
	IBOutlet NSTextField *filterField;
	IBOutlet NSWindow *mainWindow;
	IBOutlet NSTableView *outTable;
	IBOutlet NSTableColumn *applicationColumn;
	IBOutlet NSTableColumn *filePathColumn;
	IBOutlet NSTableColumn *fileSizeColumn;
	IBOutlet NSTableColumn *usernameColumn;
	IBOutlet NSTableColumn *volumeColumn;
	IBOutlet NSToolbar *toobar;
	IBOutlet NSProgressIndicator *probar;
	IBOutlet NSWindow *progSheet;
	IBOutlet NSPopUpButton *volumesBox;
	IBOutlet NSPopUpButton *usersButton;
	IBOutlet NSPopUpButton *processesButton;
	IBOutlet NSPanel *commentPanel;
	IBOutlet NSPanel *documentPanel;
	IBOutlet NSPopUpButton *commentType;
	IBOutlet NSPopUpButton *fileTypesButton;
	IBOutlet NSTextField *commentSubject;
	IBOutlet NSTextView *commentText;
	IBOutlet NSTextField *commentFrom;
	IBOutlet NSToolbarItem *listFilesButtonItem;
	IBOutlet NSToolbarItem *googleLookupButtonItem;
	IBOutlet NSToolbarItem *manLookupButtonItem;
	IBOutlet NSToolbarItem *showInFinderButtonItem;
	IBOutlet NSToolbarItem *killButtonItem;
	IBOutlet NSToolbarItem *usersButtonItem;
	IBOutlet NSToolbarItem *processButtonItem;
	IBOutlet NSTextView *documentTextView;
	IBOutlet NSTextField *progressText;
	IBOutlet NSTitlebarAccessoryViewController *superuserEnabledVC;
	IBOutlet NSTextField *bottomInfoLabel;
	IBOutlet NSMenu *contextMenu;
	IBOutlet NSMenuItem *contextShowInFinder;
	IBOutlet NSMenuItem *contextKill;
	IBOutlet NSMenuItem *contextGoogle;
	IBOutlet NSMenuItem *contextDocs;

	Boolean listing;
	LSOF *lsofData;
	int appColSort;
	int fileSizeSortFlag;
	int filePathSort;
	int usernameSort;
	int volumeSort;
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

@end
