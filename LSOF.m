//
//  LSOF.m
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import "LSOF.h"


@implementation LSOF

@synthesize appNameSort;
@synthesize filePathSort;
@synthesize fileSizeSort;
@synthesize usernameSort;
@synthesize UsernameArray;

- (id)init
{
	displayData = nil;
	data = [[[NSMutableArray alloc] init] retain];
	appNameSort = [[[NSSortDescriptor alloc] initWithKey:@"appName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] retain];
	filePathSort = [[[NSSortDescriptor alloc] initWithKey:@"filePath" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] retain];
	fileSizeSort = [[[NSSortDescriptor alloc] initWithKey:@"realSize" ascending:YES selector:@selector(compare:)] retain];
	usernameSort = [[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] retain];
	
	UsernameArray = [[NSMutableArray alloc] init];
	guidWrapperPath = [[NSString stringWithFormat:@"%@/Contents/MacOS/uidWrapper", [[NSBundle mainBundle] bundlePath]] retain];
	guidWrapperPathUTF8 = (char *)[guidWrapperPath UTF8String];
	
	return self;
}

- (void) sortDataWithDescriptors:(NSArray *)sortDescs
{
	if( displayData )
	{
		if( sortDescs )
		{
			NSMutableArray *tmpArray = [NSMutableArray arrayWithArray:[displayData sortedArrayUsingDescriptors:sortDescs]];
			[displayData removeAllObjects];
			[displayData release];
			displayData = [[NSMutableArray arrayWithArray:tmpArray] retain];
		}
		else
		{
			[displayData removeAllObjects];
			[displayData release];
			displayData = [[NSMutableArray arrayWithArray:data] retain];
		}
	}
}

- (NSInteger)dataCount
{
	NSInteger count = 0;
	if( displayData && ([displayData count] > 0) )
		count = [displayData count];
	return count;
}

- (void)releaseData
{
	if( data )
	{
		if( [data count] )
		{
			[data removeAllObjects];
		}
	}
	if( displayData )
	{
		[displayData release];
		displayData = nil;
	}
	
	if( UsernameArray )
	{
		[UsernameArray removeAllObjects];
		[UsernameArray addObject:[NSString stringWithFormat:@"All"]];
	}
}

size_t getSize( const char *f )
{
	size_t retVal = 0;
	struct stat st;
	memset(&st, 0, sizeof(st));
	if( stat( f, &st ) == 0 )
	{
		retVal = st.st_size;
	}
	return retVal;
}

- (NSString *) fileSize:(const char *)f
{
	NSString *retVal = nil;
	char *units[4] = { "B", "KB", "MB", "GB" };
	int i;
	size_t sz = 0;

	sz = getSize(f);
	for( i = 0; i < 4 && sz > 1024; i++ ) sz = sz / 1024;
	retVal = [[[NSString alloc] initWithFormat:@"%d%s", sz, units[i]] autorelease];

	return retVal;
}

- (void)filterDataWithString:(NSString *)filter forVolume:(NSString *)vol forUser:(NSString *)user
{
	NSPredicate *pred = nil;
	NSMutableString *baseString = nil;
	NSString *volString = nil;
	NSString *userString = nil;
	
	if( user && ([user compare:@"All"] != NSOrderedSame) )
	{
		userString = [NSString stringWithFormat:@"(SELF.username == '%@')", user];
	}
	
	if( vol && ([vol compare:@"All"] != NSOrderedSame) )
	{
		volString = [NSString stringWithFormat:@"(SELF.filePath BEGINSWITH[c] '/Volumes/%@')", vol];
	}
	
	if( filter && [filter length] )
	{
		baseString = [NSMutableString stringWithFormat:@"((SELF.appName contains[c] %@) OR (SELF.filePath contains[c] %@) OR (SELF.username contains[c] '%@')", filter, filter, filter];
	}
	else
	{
		baseString = [[NSMutableString alloc] init];
	}
	
	if( userString )
	{
		if( [baseString length] )
			[baseString appendString:@" AND "];
		[baseString appendString:userString];
	}
	
	if( volString )
	{
		if( [baseString length] )
			[baseString appendString:@" AND "];
		[baseString appendString:volString];
	}
	
	if( baseString && [baseString length] )
		pred = [NSPredicate predicateWithFormat:baseString];
	
	if( pred )
	{
		if( displayData && ([displayData count] > 0))
		{
			[displayData removeAllObjects];
			[displayData release];
			displayData = nil;
		}
		if( data && ([data count] > 0) )
			displayData = [[NSMutableArray arrayWithArray:[data filteredArrayUsingPredicate:pred]] retain];
	}
	else
	{
		if( displayData && ([displayData count] > 0 ))
		{
			[displayData removeAllObjects];
			[displayData release];
			displayData = nil;
		}
		if( data && ([data count] > 0) )
			displayData = [[NSMutableArray arrayWithArray:data] retain];
	}
}

- (Boolean)getCredentials
{
	Boolean retVal = YES;
	AuthorizationFlags flags =  kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
	AuthorizationItem progs[] = { {kAuthorizationRightExecute, strlen(guidWrapperPathUTF8), guidWrapperPathUTF8, 0} };
	
	AuthorizationRights rights = { sizeof(progs)/sizeof(AuthorizationItem), progs };
	
	if( authRef == nil )
	{
		if( AuthorizationCreate( NULL, kAuthorizationEmptyEnvironment, flags, &authRef ) != errAuthorizationSuccess )
		{
			retVal = NO;
			if( authRef )
				AuthorizationFree(authRef, kAuthorizationFlagDefaults);
			authRef = nil;
		}
		else if( AuthorizationCopyRights( authRef, &rights, NULL, flags, NULL ) != errAuthorizationSuccess )
		{
			retVal = NO;
			if( authRef )
				AuthorizationFree(authRef, kAuthorizationFlagDefaults);
			authRef = nil;
		}
	}
	
	return retVal;
}

- (void)releaseCredentials
{
	if( authRef )
		AuthorizationFree(authRef, kAuthorizationFlagDefaults);
	authRef = nil;
}

- (void)getData
{
	FILE *lsof = NULL;
	char *args[] = { "/usr/sbin/lsof", NULL };
	char line[4096];
	char *p, *p2, *lim;
	Boolean one = NO;
	NSMutableArray *lineArray;
	NSString *tst;
	int i;
	Boolean isSet = NO;
	
	if( CFPreferencesGetAppBooleanValue( CFSTR( "lsofFullList" ), kCFPreferencesCurrentApplication, &isSet ) )
	{
		if( ![self getCredentials] )
		{
			NSLog(@"Error obtaining credencials for lsof\n");
			lsof = NULL;
		}
		else
		{
			if( AuthorizationExecuteWithPrivileges( authRef, [guidWrapperPath UTF8String], kAuthorizationFlagDefaults, args, &lsof) != errAuthorizationSuccess )
			{
				NSLog( @"error running lsof as root\n" );
				lsof = NULL;
			}
		}
	}
	else if( (lsof = popen(args[0], "r")) == NULL )
	{
		NSLog(@"Unable to open lsof command");
		lsof = NULL;
	}
	
	if( lsof )
	{
		[self releaseData];
		while( fgets( line, 4096, lsof ) )
		{
			if( one )
			{
				/* passed first line */
				lineArray = [[NSMutableArray alloc] init];
				
				for( p = line, p2 = line, lim = &line[strlen(line)], i = 0; p < lim; p++ )
				{
					if( *p <= ' ' && i < 8 )
					{
						while( (p < lim) && (*p <= ' ') ) 
						{	
							*p = 0;
							p++;
						}
						[lineArray addObject:[[NSString alloc] initWithFormat:@"%s", p2]];
						p2 = p;
						i++;
					}
					else if( (*p <= ' ') && (i >= 8) )
					{
						while( p < lim )
						{
							if( *p == '\n' )
								*p = 0;
							p++;
						}
						[lineArray addObject:[[NSString alloc] initWithFormat:@"%s", p2]];
						i++;
					}
				}
				if( [[lineArray objectAtIndex:4] isEqualToString:[NSString stringWithFormat:@"REG"]] )
				{
					OpenFile *f = [[OpenFile alloc] init];
					tst = [[self fileSize:[[lineArray objectAtIndex:8] UTF8String]] retain];
					if( tst )
					{
						[f setFileSize:tst];
						[tst release];
					}
					[f setAppName:[lineArray objectAtIndex:0]];
					[f setFilePath:[lineArray objectAtIndex:8]];
					[f setPid:[[lineArray objectAtIndex:1] integerValue]];
					[f setRealSize:[NSNumber numberWithLongLong:getSize([[lineArray objectAtIndex:8] UTF8String])]];
					[f setUsername:[lineArray objectAtIndex:2]];
					[self addUserName:[lineArray objectAtIndex:2]];
					[data addObject:f];
					[lineArray release];
				}
				else
					[lineArray release];
			}
			else
			{
				one = YES;
			}
		}
		fclose(lsof);
	}
	
	if( displayData && ([displayData count] > 0))
	{
		[displayData removeAllObjects];
		[displayData release];
		displayData = nil;
	}
	displayData = [[NSMutableArray arrayWithArray:data] retain];
}

- (void)addUserName:(NSString *)username
{
	int found = 0;
	id x;
	for( x in UsernameArray )
	{
		if( [(NSString *)x compare:username] == NSOrderedSame )
		{
			found = 1;
			break;
		}
	}
	if( !found )
	{
		[UsernameArray addObject:[username copy]];
	}
}


- (pid_t)getPidForRow:(int)rowIx
{
	pid_t retVal = -1;
	OpenFile *f = [displayData objectAtIndex:rowIx];
	if( f )
		retVal = [f pid];
	return retVal;
}

- (NSString *)getFilePathForRow:(int)rowIx
{
	NSString * retVal = nil;
	OpenFile *f = [displayData objectAtIndex:rowIx];
	if( f )
		retVal = [f filePath];
	return retVal;
}

- (NSString *)getAppNameForRow:(int)rowIx
{
	NSString * retVal = nil;
	OpenFile *f = [displayData objectAtIndex:rowIx];
	if( f )
		retVal = [f appName];
	return retVal;
}

- (NSString *)getFileSizeForRow:(int)rowIx
{
	NSString * retVal = nil;
	OpenFile *f = [displayData objectAtIndex:rowIx];
	if( f )
		retVal = [f fileSize];
	return retVal;
}

- (NSString *)getUserForRow:(int)rowIx
{
	NSString * retVal = nil;
	OpenFile *f = [displayData objectAtIndex:rowIx];
	if( f )
		retVal = [f username];
	return retVal;
}

@end
