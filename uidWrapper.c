/*
 *  uidWrapper.c
 *  WhatsOpen
 *
 *  Created by Franklin Marmon on 9/11/08.
 *  Copyright 2008 AGASupport. All rights reserved.
 *
 */

#include "uidWrapper.h"

int main(int argc, char *argv[])
{
	FILE *f = NULL;
	char buff[4096];
	
	if (setuid (geteuid()) != 0) {
		// failed
		return 1;
	}

	if ( (f = popen( argv[1], "r" )) ) {
		while( fgets( buff, 4096, f ) ) {
			fprintf(stdout, "%s", buff);
		}
		fflush(stdout);
		fclose(f);
	}
	
	return 0;
}
