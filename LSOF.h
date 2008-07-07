//
//  LSOF.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface LSOF : NSObject {
	NSMutableArray *data;
}

- (void)getData:(NSString *)filter;
- (NSInteger)dataCount;
- (NSString *)getField:(int)field inRow:(int)row;
- (void)releaseData;
- (pid_t)getPidOfRow:(int)rowIx;

@end
