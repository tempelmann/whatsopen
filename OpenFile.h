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

@interface OpenFile : NSObject {
	NSString *appName;
	NSString *filePath;
	NSString *fileSize;
	pid_t pid;
	NSNumber *realSize; 
	NSString *username;
	//NSInteger cputime;
	fileTypes fileType;
}

@property(copy,readwrite) NSString *appName;
@property(copy,readwrite) NSString *filePath;
@property(copy,readwrite) NSString *fileSize;
@property(copy,readwrite) NSNumber *realSize;
@property(copy,readwrite) NSString *username;
@property pid_t pid;
//@property NSInteger cputime;
@property fileTypes fileType;


@end
