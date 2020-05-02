//
//  OpenFile.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 8/5/08.
//  Copyright 2008 The Hyde Company. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	Undefined,
	RegularFile,
	Directory,
	Other
}  fileTypes;

@interface OpenFile : NSObject

@property(copy,readwrite) NSString *appName;
@property(copy,readwrite) NSString *filePath;
@property(copy,readwrite) NSString *fileSize;
@property(copy,readwrite) NSNumber *realSize;
@property(copy,readwrite) NSString *username;
@property(copy,readwrite) NSString *volName;
@property pid_t pid;
@property fileTypes fileType;

@end
