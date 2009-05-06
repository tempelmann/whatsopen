//
//  OpenFile.h
//  WhatsOpen
//
//  Created by Franklin Marmon on 8/5/08.
//  Copyright 2008 The Hyde Company. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef int fileTypes;
#define NormalFile 1
#define IPv4File   2

@interface OpenFile : NSObject {
	NSString *appName;
	NSString *filePath;
	NSString *fileSize;
	NSInteger pid;
	NSNumber *realSize; 
	NSString *username;
	NSInteger cputime;
	fileTypes fileType;
}

@property(copy,readwrite) NSString *appName;
@property(copy,readwrite) NSString *filePath;
@property(copy,readwrite) NSString *fileSize;
@property(copy,readwrite) NSNumber *realSize;
@property(copy,readwrite) NSString *username;
@property NSInteger pid;
@property NSInteger cputime;
@property fileTypes fileType;


@end
