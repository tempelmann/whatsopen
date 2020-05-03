//
//  SmarterTableView.m
//  WhatsOpen
//
//  Created by Thomas Tempelmann on 03.05.20.
//

#import "SmarterTableView.h"

@implementation SmarterTableView

- (NSMenu*) menuForEvent:(NSEvent*)event // override
{
	// Get to row at point
	NSInteger row = [self rowAtPoint:[self convertPoint:event.locationInWindow fromView:nil]];
	if (row >= 0) {
		// and check whether it is selected
		if (NOT [self isRowSelected:row]) {
			// No -> select that row
			[self selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
		}
	}
	return [super menuForEvent:event];
}

@end
