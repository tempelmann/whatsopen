//
//  LSOF.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sys/stat.h>

@interface LSOF : NSObject {
	NSMutableArray *data;
}

- (void)getData:(NSString *)filter forVolume:(NSString *)vol;
- (NSInteger)dataCount;
- (NSString *)getField:(int)field inRow:(int)row;
- (NSString *)fileSize:(const char *)f;
- (void)releaseData;
- (pid_t)getPidOfRow:(int)rowIx;
- (NSString *)getFileOfRow:(int)rowIx;

@end
