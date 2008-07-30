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
	IBOutlet NSToolbar *toobar;
	IBOutlet NSProgressIndicator *probar;
	IBOutlet NSWindow *progSheet;
	IBOutlet NSPopUpButton *volumesBox;

	Boolean listing;
	LSOF *lsofData;
	FinderApplication *theFinder;
}

- (IBAction) listFiles:(id)sender;
- (IBAction) killApplication:(id)sender;
- (IBAction) openInFinder:(id)sender;
// - (IBAction) showInfoFinder:(id)sender;

// add our volumes to the UI volumes filter
- (void)addVolumesToUI;

// table delegates
- (int)numberOfRowsInTableView:(NSTableView *)table;
- (id)tableView:(NSTableView *)table objectValueForTableColumn:(NSTableColumn *)col row:(int)rowIx;
- (Boolean)tableView:(NSTableView *)table shouldEditTableColumn:(NSTableColumn *)col row:(int)row;
- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)row mouseLocation:(NSPoint)mouseLocation;
- (void)progDidEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;

@end
