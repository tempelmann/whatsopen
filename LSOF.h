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
	NSSortDescriptor *usernameSort;
	NSSortDescriptor *cpuSort;
	
	NSMutableArray   *UsernameArray;
	
	AuthorizationRef authRef;
	NSString         *guidWrapperPath;
	NSString         *cpuListerPath;
	char             *guidWrapperPathUTF8;
	NSColor *ipv4Color;
}

@property(readonly) NSSortDescriptor *appNameSort;
@property(readonly) NSSortDescriptor *fileSizeSort;
@property(readonly) NSSortDescriptor *filePathSort;
@property(readonly) NSSortDescriptor *usernameSort;
@property(readonly) NSMutableArray *UsernameArray;
@property(readonly) NSSortDescriptor *cpuSort;
@property(copy)     NSColor *ipv4Color;
		  
- (void)getData:(NSTextField *)progressText;
- (NSInteger)dataCount;
- (NSString *)fileSize:(const char *)f;
- (void)releaseData;
- (pid_t)getPidForRow:(int)rowIx;
- (NSString *)getFilePathForRow:(int)rowIx;
- (NSString *)getAppNameForRow:(int)rowIx;
- (NSString *)getFileSizeForRow:(int)rowIx;
- (NSString *)getUserForRow:(int)rowIx;
- (int)getCpuTimeForRow:(int)rowIx;
- (fileTypes)getFileTypeForRow:(int)rowIx;

- (void)addUserName:(NSString *)username;

- (void)filterDataWithString:(NSString *)filtr forVolume:(NSString *)vol forUser:(NSString *)user forType:(int)ftype;
- (void) sortDataWithDescriptors:(NSArray *)sortDescs;

@end
