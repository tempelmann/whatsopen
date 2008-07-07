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
	[self getData:nil];
	
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

- (void)getData:(NSString *)filter
{
	FILE *lsof;
	NSString *cmd_string;
	char line[4096];
	char *p, *p2, *lim;
	Boolean one = NO;
	NSMutableArray *lineArray;
	
	if( filter && [filter length] )
	{
		cmd_string = [[NSString alloc] initWithFormat:@"lsof | grep %@", filter];
	}
	else
	{
		cmd_string = [[NSString alloc] initWithString:@"lsof"];
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
				for( p = line, p2 = line, lim = &line[strlen(line)]; p < lim; p++ )
				{
					if( *p <= ' ' )
					{
						while( (p < lim) && (*p <= ' ') ) 
						{	
							*p = 0;
							p++;
						}
						[lineArray addObject:[[NSString alloc] initWithFormat:@"%s", p2]];
						p2 = p;
					}
				}
				if( [[lineArray objectAtIndex:4] isEqualToString:[NSString stringWithFormat:@"REG"]] )
					[data addObject:lineArray];
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
