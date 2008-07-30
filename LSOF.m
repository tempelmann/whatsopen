//
//  LSOF.m
//  WhatsOpen
//
//  Created by Franklin Marmon on 6/24/08.
//  Copyright 2008 AGASupport. All rights reserved.
//

#import "LSOF.h"


@implementation LSOF

- (id)init
{
	data = [[[NSMutableArray alloc] init] retain];
	
	return self;
}

- (NSInteger)dataCount
{
	return [data count];
}

- (void)releaseData
{
	NSMutableArray *row;
	if( data )
	{
		if( [data count] )
		{
			for( row in data )
				[row removeAllObjects];
			[data removeAllObjects];
		}
	}
}

- (NSString *) fileSize:(const char *)f
{
	NSString *retVal = nil;
	struct stat st;
	char *units[4] = { "B", "KB", "MB", "GB" };
	int i;
	size_t sz = 0;
	memset(&st, 0, sizeof(st));
	
	if( stat( f, &st ) == 0 )
	{
		sz = st.st_size;
		for( i = 0; i < 4 && sz > 1024; i++ ) sz = sz / 1024;
		retVal = [[[NSString alloc] initWithFormat:@"%d%s", sz, units[i]] autorelease];
	}
	else
		NSLog(@"stat error %s: %s", f, strerror(errno));
	return retVal;
}

- (void)getData:(NSString *)filter forVolume:(NSString *)vol
{
	FILE *lsof;
	NSString *cmd_string;
	char line[4096];
	char *p, *p2, *lim;
	Boolean one = NO;
	NSMutableArray *lineArray;
	NSString *tst;
	int i;
	
	if( filter && [filter length] )
	{
		cmd_string = [[NSString alloc] initWithFormat:@"lsof | grep %@", filter];
		one = YES;
	}
	else
	{
		cmd_string = [[NSString alloc] initWithString:@"lsof"];
	}
	
	if( vol && [vol length] )
	{
		if( [vol compare:@"\"All\""] != NSOrderedSame )
		{
			NSString *p = cmd_string;
			cmd_string = [cmd_string stringByAppendingString:[NSString stringWithFormat:@" | grep %@", vol]];
			[p release];
			one = YES;
		}
	}
	
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
					tst = [[self fileSize:[[lineArray objectAtIndex:8] UTF8String]] retain];
					if( tst )
					{
						[lineArray addObject:tst];
						[tst release];
					}
					[data addObject:lineArray];
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
	
	NSLog(@"data filled, %d objects", [data count]);
}

- (pid_t)getPidOfRow:(int)rowIx
{
	pid_t retVal = -1;
	NSMutableArray *row = [data objectAtIndex:rowIx];
	if( row )
		retVal = [[row objectAtIndex:1] integerValue];
	return retVal;
}

- (NSString *)getFileOfRow:(int)rowIx
{
	NSString * retVal = nil;
	NSMutableArray *row = [data objectAtIndex:rowIx];
	if( row )
		retVal = [row objectAtIndex:8];
	return retVal;
}

- (NSString *)getField:(int)field inRow:(int)rowIx
{
	NSString *retVal = nil;
	NSMutableArray *row;
	
	if( rowIx < [data count] )
	{
		row = [data objectAtIndex:rowIx];

		if( row )
		{
			if( field < [row count] )
				retVal = [row objectAtIndex:field];
		}
	}
	
	return retVal;
}

@end
