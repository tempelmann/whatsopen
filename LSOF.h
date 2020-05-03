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


@interface LSOF : NSObject

@property(readonly) NSSortDescriptor *processNameSortDesc;
@property(readonly) NSSortDescriptor *fileSizeSortDesc;
@property(readonly) NSSortDescriptor *filePathSortDesc;
@property(readonly) NSSortDescriptor *usernameSortDesc;
@property(readonly) NSSortDescriptor *volumeSortDesc;

@property(readonly) NSMutableDictionary<NSString*,NSNumber*> *allUserNames;
@property(readonly) NSMutableDictionary<NSString*,NSNumber*> *allProcessNames;
@property(readonly) NSMutableDictionary<NSString*,NSNumber*> *allVolumes;	// key is volume name

@property(copy)     NSColor *alternateColor;

- (BOOL)getData:(NSTextField *)progressText;
- (NSInteger)dataCount;
- (NSInteger)totalCount;
- (void)releaseData;
- (pid_t)getPidForRow:(NSInteger)rowIx;
- (NSString *)getFilePathForRow:(NSInteger)rowIx;
- (NSString *)getAppNameForRow:(NSInteger)rowIx;
- (NSString *)getFileSizeForRow:(NSInteger)rowIx;
- (NSString *)getUserForRow:(NSInteger)rowIx;
- (NSString *)getVolumeForRow:(NSInteger)rowIx;
- (fileTypes)getFileTypeForRow:(NSInteger)rowIx;

- (void)filterDataWithString:(NSString *)filtr forVolume:(NSString *)vol forUser:(NSString *)user forProcess:(NSString *)process forType:(fileTypes)ftype;
- (void) sortDataWithDescriptors:(NSArray *)sortDescs;

+ (NSString *)displayFileSize:(size_t)size;

@end
