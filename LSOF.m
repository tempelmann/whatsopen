//
//  LSOF.m
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import "LSOF.h"

@interface LSOF()
	{
		NSMutableArray		*data;
		NSMutableArray		*displayData;
		AuthorizationRef	authRef;
		NSColor				*alternateColor;
	}

	@property(strong) NSString *LSOFTool;
	@property(strong) NSSortDescriptor *processNameSortDesc;
	@property(strong) NSSortDescriptor *fileSizeSortDesc;
	@property(strong) NSSortDescriptor *filePathSortDesc;
	@property(strong) NSSortDescriptor *usernameSortDesc;
	@property(strong) NSMutableDictionary<NSString*,NSNumber*> *allUserNames;
	@property(strong) NSMutableDictionary<NSString*,NSNumber*> *allProcessNames;
	@property(strong) NSMutableDictionary<NSString*,NSNumber*> *allVolumes;
@end


@implementation LSOF

@synthesize alternateColor;


#define Use1024 0

- (id)init
{
	self = [super init];
	if (self) {
		displayData = nil;
		data = [[NSMutableArray alloc] init];
		self.processNameSortDesc = [[NSSortDescriptor alloc] initWithKey:@"appName"
												  ascending:YES
												   selector:@selector(localizedCaseInsensitiveCompare:)];
		self.filePathSortDesc = [[NSSortDescriptor alloc] initWithKey:@"filePath"
												   ascending:YES
													selector:@selector(localizedCaseInsensitiveCompare:)];
		self.fileSizeSortDesc = [[NSSortDescriptor alloc] initWithKey:@"realSize" ascending:YES selector:@selector(compare:)];
		self.usernameSortDesc = [[NSSortDescriptor alloc] initWithKey:@"username"
												   ascending:YES
													selector:@selector(localizedCaseInsensitiveCompare:)];
		//self.cpuSortDesc = [[NSSortDescriptor alloc] initWithKey:@"cputime" ascending:YES selector:@selector(compare:)];
		
		self.LSOFTool = @"/usr/sbin/lsof";
		
		self.allUserNames = [NSMutableDictionary new];
		self.allProcessNames = [NSMutableDictionary new];
		self.allVolumes = [NSMutableDictionary new];
		
		[NSObject exposeBinding:@"alternateColor"];
	}
	return self;
}

- (void)sortDataWithDescriptors:(NSArray *)sortDescs
{
	if (displayData) {
		if (sortDescs) {
			NSMutableArray *tmpArray = [NSMutableArray arrayWithArray:[displayData sortedArrayUsingDescriptors:sortDescs]];
			displayData = [NSMutableArray arrayWithArray:tmpArray];
		}
		else {
			displayData = [NSMutableArray arrayWithArray:data];
		}
	}
}

- (NSInteger)dataCount
{
	return [displayData count];
}

- (NSInteger)totalCount
{
	return [data count];
}

- (void)releaseData
{
	if ([data count]) {
		[data removeAllObjects];
	}
	
	displayData = nil;
	
	[self.allProcessNames removeAllObjects];
	[self.allUserNames removeAllObjects];
	[self.allVolumes removeAllObjects];
}

- (void)filterDataWithString:(NSString *)filter forVolume:(NSString *)vol forUser:(NSString *)user forProcess:(NSString *)process forType:(fileTypes)ftype
{
	NSPredicate *pred = nil;
	NSMutableString *baseString = nil;
	NSString *volString = nil;
	NSString *userString = nil;
	NSString *processString = nil;
	NSString *typeString = nil;
	
	if (user) {
		userString = [NSString stringWithFormat:@"(SELF.username == '%@')", user];
	}
	
	if (process) {
		processString = [NSString stringWithFormat:@"(SELF.appName == '%@')", process];
	}
	
	if (vol) {
		volString = [NSString stringWithFormat:@"(SELF.volName == '%@')", vol];
	}
	
	if (ftype > 0) {
		typeString = [NSString stringWithFormat:@"(SELF.fileType == %ld)", (long)ftype];
	}
	
	if ([filter length] > 0) {
		baseString = [NSMutableString
					  stringWithFormat:
					  @"((SELF.appName contains[cd] '%@') OR (SELF.filePath contains[cd] '%@') OR (SELF.username contains[cd] '%@'))",
					  filter, filter, filter];
	}
	else {
		baseString = [[NSMutableString alloc] init];
	}
	
	if (userString) {
		if ([baseString length])
			[baseString appendString:@" AND "];
		[baseString appendString:userString];
	}
	
	if (processString) {
		if ([baseString length])
			[baseString appendString:@" AND "];
		[baseString appendString:processString];
	}
	
	if (volString) {
		if ([baseString length])
			[baseString appendString:@" AND "];
		[baseString appendString:volString];
	}
	
	if (typeString) {
		if ([baseString length])
			[baseString appendString:@" AND "];
		[baseString appendString:typeString];
	}
	
	if (baseString && [baseString length])
		pred = [NSPredicate predicateWithFormat:baseString];
	
	if (pred) {
		if (displayData && ([displayData count] > 0)) {
			displayData = nil;
		}
		if (data && ([data count] > 0))
			displayData = [NSMutableArray arrayWithArray:[data filteredArrayUsingPredicate:pred]];
	}
	else {
		if (displayData && ([displayData count] > 0)) {
			displayData = nil;
		}
		if (data && ([data count] > 0))
			displayData = [NSMutableArray arrayWithArray:data];
	}
}

- (Boolean)getCredentials
{
	Boolean retVal = YES;

	if (authRef == nil) {
		const char *username = NULL, *password = NULL;
		NSUInteger pwlength = 0;
		
		// Look up username and password in the Keychain
		const void* qkeys[] = {kSecClass, kSecAttrLabel, kSecMatchLimit, kSecReturnAttributes, kSecReturnData};
		const void* qvals[] = {kSecClassGenericPassword, CFSTR("WhatsOpen"), kSecMatchLimitOne, kCFBooleanTrue, kCFBooleanTrue};
		CFDictionaryRef query = CFDictionaryCreate(NULL, qkeys, qvals, 5, NULL, NULL);
		CFTypeRef keychainResult = nil;
		OSStatus res = SecItemCopyMatching (query, &keychainResult);
		if (res == 0 && keychainResult) {
			NSDictionary *d = (__bridge NSDictionary *)(keychainResult);
			username = [(NSString*)d[(NSString*)kSecAttrAccount] UTF8String];
			NSData *data = d[(NSString*)kSecValueData]; 
			password = [data bytes];
			pwlength = [data length];
		}
		CFRelease (query);
		
		AuthorizationItem username_password[2];
		username_password[0].name = "username";
		username_password[0].value = (void*) username;
		username_password[0].valueLength = (username == nil) ? 0 : strlen(username);
		username_password[1].name = "password";
		username_password[1].value = (void*) password;
		username_password[1].valueLength = pwlength;
		AuthorizationItemSet auths = {username != nil ? 2 : 0, username_password};
		
		const char *tool = self.LSOFTool.UTF8String;
		AuthorizationItem progs[] = {{kAuthorizationRightExecute, strlen(tool), (void*)tool, 0}};
		AuthorizationRights rights = {sizeof(progs) / sizeof(AuthorizationItem), progs};

		AuthorizationFlags flags = kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
		
		if (AuthorizationCreate (&rights, &auths, flags, &authRef) != errAuthorizationSuccess) {
			retVal = NO;
		}

		if (keychainResult) {
			CFRelease (keychainResult);	// call this only after AuthorizationCreate() in order to keep username and pw alive for that call
		}
	}

	return retVal;
}

- (void)releaseCredentials
{
	if (authRef) {
		AuthorizationFree(authRef, kAuthorizationFlagDefaults);
	}
	authRef = nil;
}

- (BOOL)getData:(NSTextField *)progressText
{
	//[progressText setValue:@"Getting File Listing"];
	
	NSArray<NSString*> *args = @[
		self.LSOFTool,
		@"-FpcLustn0",
		@"-nw",
		@"-a", @"-p", @"124",
		@"/"
	];
	NSString *cmd = [args componentsJoinedByString:@" "];	// as shell command line, including args in the same string
	char *cargs[16];
	char **argp = cargs;
	for (NSInteger i = 1; i < args.count; ++i) {
		*(argp++) = (char*) args[i].UTF8String;
	}
	*(argp++) = NULL;
	
	BOOL was_popen = NO;
	FILE *lsof = NULL;
	if ([NSUserDefaults.standardUserDefaults boolForKey:@"lsofFullList"]) {
		if (![self getCredentials]) {
			NSLog(@"Error obtaining credencials for lsof\n");
			return NO;
		}
		else {
			NSLog(@"invoking (root): %@", cmd);
			OSStatus res = AuthorizationExecuteWithPrivileges (authRef, self.LSOFTool.UTF8String, kAuthorizationFlagDefaults, cargs, &lsof);
			if (res != errAuthorizationSuccess) {
				NSLog(@"Running lsof as root failed\n");
				return NO;
			}
		}
	} else {
		NSLog(@"invoking: %@", cmd);
		if ((lsof = popen(cmd.UTF8String, "r")) == NULL) {
			NSLog(@"popen(lsof) failed");
			return NO;
		}
		was_popen = YES;
	}
	
	[self releaseData];
	
	pid_t latestProcessID = 0;
	NSString *latestProcessName = nil;
	NSString *latestUserName = nil;
 	OpenFile *currentFile = nil;
	
	while (NOT feof(lsof)) {
		size_t lineLen;
		char *lineStart = fgetln (lsof, &lineLen);
		if (lineLen == 0) {
			// keep waiting for more
			continue;
		}
		if (lineLen <= 2) {
			// empty?!
			NSLog(@"lsof returned empty line");
			continue;
		}
		
		NSString *line = [[NSString alloc] initWithBytes:lineStart length:lineLen-2 encoding:NSUTF8StringEncoding];
		NSArray<NSString*> *fields = [line componentsSeparatedByString:@"\000"];
		
		for (NSString *field in fields) {
			unichar tag = [field characterAtIndex:0];
			NSString *value = [field substringFromIndex:1];
			switch (tag) {
				case 'p':
					{
						// process ID
						latestProcessID = (int) [value integerValue];
					}
					break;
				case 'c':
					{
						// process Name
						latestProcessName = value;
					}
					break;
				case 'u':
					{
						// user ID - ignore
					}
					break;
				case 'L':
					{
						// user Name
						latestUserName = value;
					}
					break;
				case 'f':
					{
						// new file
		 	 			currentFile = [OpenFile new];
		 	 			currentFile.appName = latestProcessName;
		 	 			currentFile.pid = latestProcessID;
		 	 			currentFile.username = latestUserName;
		 				[data addObject:currentFile];
		 				if (latestProcessName != nil && latestUserName != nil) {
							self.allProcessNames[latestProcessName] = @([self.allProcessNames[latestProcessName] integerValue] + 1);
							self.allUserNames[latestUserName] = @([self.allUserNames[latestUserName] integerValue] + 1);
						} else {
							NSLog(@"Error: new file but no process or uname");
						}
					}
					break;
				case 't':
					{
						// type
						fileTypes t = Undefined;
						if ([value isEqualToString:@"REG"]) {
							t = RegularFile;
						} else if ([value isEqualToString:@"DIR"]) {
							t = Directory;
						} else {
							t = Other;
						}
		 	 			currentFile.fileType = t;
					}
					break;
				case 's':
					{
						// file size
						NSInteger size = [value integerValue];
						if (currentFile.fileType == RegularFile) {
							currentFile.fileSize = [self.class displayFileSize:size];
						} else if (currentFile.fileType == Directory) {
							currentFile.fileSize = @"–";
						}
		 	 			currentFile.realSize = [NSNumber numberWithInteger:size];
					}
					break;
				case 'n':
					{
						// file path
						currentFile.filePath = value;
						NSURL *url = [NSURL fileURLWithPath:value];
						NSString *volName = nil;
						[url getResourceValue:&volName forKey:NSURLVolumeNameKey error:nil];
						currentFile.volName = volName;
						if (volName) { 
							self.allVolumes[volName] = @([self.allVolumes[volName] integerValue] + 1);
						}
					}
					break;
				default:
					assert(false);
			}
		}
	}
	
	int error = ferror(lsof);
	if (error) {
		NSLog(@"Error: %d", error);
	}
	
	if (was_popen) {
		pclose(lsof);
	} else {
		fclose(lsof);
	}
	
	if (data.count == 0) {
		NSLog(@"Strange: no results");
	}
	
	displayData = [NSMutableArray arrayWithArray:data];
	return YES;
}

- (OpenFile*)fileAtIndex:(NSInteger)index
{
	@try {
		OpenFile *f = [displayData objectAtIndex:index];
		return f;
	} @catch (NSException *exception) {
		return nil;
	}
}

- (pid_t)getPidForRow:(NSInteger)rowIx
{
	pid_t retVal = -1;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f pid];
	}
	return retVal;
}

- (NSString *)getFilePathForRow:(NSInteger)rowIx
{
	NSString *retVal = nil;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f filePath];
	}
	return retVal;
}

- (NSString *)getAppNameForRow:(NSInteger)rowIx
{
	NSString *retVal = nil;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f appName];
	}
	return retVal;
}

- (NSString *)getFileSizeForRow:(NSInteger)rowIx
{
	NSString *retVal = nil;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f fileSize];
	}
	return retVal;
}

- (NSString *)getUserForRow:(NSInteger)rowIx
{
	NSString *retVal = nil;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f username];
	}
	return retVal;
}

/*
- (NSInteger)getCpuTimeForRow:(NSInteger)rowIx
{
	NSInteger retVal = 0;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f cputime];
	}
	return retVal;
}
*/

- (fileTypes)getFileTypeForRow:(NSInteger)rowIx
{
	fileTypes retVal = Undefined;
	OpenFile *f = [self fileAtIndex:rowIx];
	if (f) {
		retVal = [f fileType];
	}
	return retVal;
}

/*
static size_t getSize(const char *f)
{
	size_t retVal = 0;
	struct stat st;
	memset(&st, 0, sizeof(st));
	if (stat(f, &st) == 0) {
		retVal = st.st_size;
	}
	return retVal;
}
*/

+ (NSString *)displayFileSize:(size_t)size
{
	NSString *retVal = nil;
	#if Use1024
		char *units[4] = {"B", "KiB", "MiB", "GiB"};
		const int k = 1024;
	#else
		char *units[4] = {"B", "KB", "MB", "GB"};
		const int k = 1000;
	#endif
	size_t sz = size;
	int i = 0;
	for (; i < 4 && sz > k; i++) {
		sz = sz / k;
	}
	retVal = [[NSString alloc] initWithFormat:@"%zu %s", sz, units[i]];
	return retVal;
}

@end
