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

- (id)init
{
	displayData = nil;
	data = [[[NSMutableArray alloc] init] retain];
	appNameSort = [[[NSSortDescriptor alloc] initWithKey:@"appName" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] retain];
	filePathSort = [[[NSSortDescriptor alloc] initWithKey:@"filePath" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] retain];
	fileSizeSort = [[[NSSortDescriptor alloc] initWithKey:@"realSize" ascending:YES selector:@selector(compare:)] retain];
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

- (void)filterDataWithString:(NSString *)filter forVolume:(NSString *)vol
{
	NSPredicate *pred = nil;
	
	if( [vol compare:@"All"] != NSOrderedSame )
	{
		if( filter && [filter length])
		{
			pred = [NSPredicate predicateWithFormat:@"((SELF.appName CONTAINS[c] %@) OR (SELF.filePath CONTAINS[c] %@)) AND (SELF.filePath BEGINSWITH[c] '%@')", 
					filter, filter, [NSString stringWithFormat:@"/Volumes/%@", vol]];
		}
		else
		{
			pred = [NSPredicate predicateWithFormat:@"SELF.filePath BEGINSWITH[c] '%@'", [NSString stringWithFormat:@"/Volumes/%@", vol]];
		}
	}
	else if( filter && [filter length])
	{
		pred = [NSPredicate predicateWithFormat:@"(SELF.appName contains[c] %@) OR (SELF.filePath contains[c] %@)", 
				filter, filter];
	}
	
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

- (void)getData
{
	FILE *lsof;
	NSString *cmd_string = [[NSString alloc] initWithString:@"lsof"];
	char line[4096];
	char *p, *p2, *lim;
	Boolean one = NO;
	NSMutableArray *lineArray;
	NSString *tst;
	int i;
	
	if( (lsof = popen([cmd_string UTF8String], "r")) == NULL )
	{
		NSLog(@"Unable to open lsof command");
	}
	else
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

@end
