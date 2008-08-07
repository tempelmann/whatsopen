//
//  LSOF.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <sys/stat.h>
#import "OpenFile.h"

@interface LSOF : NSObject {
	NSMutableArray *data;
	NSMutableArray *displayData;
	NSSortDescriptor *appNameSort;
	NSSortDescriptor *fileSizeSort;
	NSSortDescriptor *filePathSort;
}

@property(readonly) NSSortDescriptor *appNameSort;
@property(readonly) NSSortDescriptor *fileSizeSort;
@property(readonly) NSSortDescriptor *filePathSort;

- (void)getData;
- (NSInteger)dataCount;
- (NSString *)fileSize:(const char *)f;
- (void)releaseData;
- (pid_t)getPidForRow:(int)rowIx;
- (NSString *)getFilePathForRow:(int)rowIx;
- (NSString *)getAppNameForRow:(int)rowIx;
- (NSString *)getFileSizeForRow:(int)rowIx;
- (void)filterDataWithString:(NSString *)filtr forVolume:(NSString *)vol;
- (void) sortDataWithDescriptors:(NSArray *)sortDescs;

@end
