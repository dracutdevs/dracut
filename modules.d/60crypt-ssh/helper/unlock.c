
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/mman.h>

#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include <stdlib.h>

#include "crypttab.h"

static const int kPasswordSize = 8192;
static const char *kDevPath = "/dev";
static const char *kCrypttabPath = "/etc/crypttab";
static const char *kNoKeyFile = "none";

int runchild( const char *input, int inputSize, const char *path, char *const args[] )
{
	int childStdin[ 2 ] = { -1, -1 };

	pipe( childStdin );

	pid_t childPid = fork();

	int childStatus;

	if( childPid == 0 ) { // We are the child
		close( 0 );
		close( childStdin[ 1 ] );

		dup2( childStdin[ 0 ], 0 ); // make stdin

		int rc = execv( path, args );
		exit( rc );
	} else {
		close( childStdin[ 0 ] );

		write( childStdin[ 1 ], input, inputSize );
		close( childStdin[ 1 ] );

		waitpid( childPid, &childStatus, 0 );
	}

	if( WIFEXITED( childStatus ) ) {
		return WEXITSTATUS( childStatus );
	} else {
		return 1;
	}
}

int main( int argc, const char ** argv )
{
	int numProvidedNames = argc - 1;
	const char **providedNames = argv + 1;
	
	struct crypttab crypttab = crypttab_parse( kCrypttabPath );
	if( crypttab.size == 0 ) {
		fprintf( stderr, "/etc/crypttab is empty or invalid\n" );
		return 254;
	}

	int *unlockList = calloc( crypttab.size, sizeof( int ) );
	if( !unlockList ) {
		fprintf( stderr, "Could not allocate memory\n" );
		return 255;
	}

	int devicesToUnlock = 0;
	int errorExit = 0;

	if( numProvidedNames > 0 ) {
		for( int providedName = 0; providedName < numProvidedNames; ++providedName ) {
			const char *name = providedNames[ providedName ];
			int found = 0;

			for( int entryIdx = 0; entryIdx < crypttab.size; ++entryIdx ) {
				struct crypttab_entry *entry = crypttab.entries + entryIdx;
				if( strncmp( name, entry->mapper, strlen( name ) ) == 0 ) {
					unlockList[ entryIdx ] = 1;
					found = 1;
					++devicesToUnlock;
					break;
				}
			}
	
			if( !found ) {
				fprintf( stderr, "LUKS device matching '%s' not found in /etc/crypttab\n", name );
				errorExit = 1;
			}
		}
	} else {
		// Unless provided with a specific list of devices to unlock, 
		// only open devices that don't require a keyfile
		for( int entryIdx = 0; entryIdx < crypttab.size; ++entryIdx ) {
			struct crypttab_entry *entry = crypttab.entries + entryIdx;
			if( strcmp( entry->keyfile, kNoKeyFile ) == 0 ) {
				unlockList[ entryIdx ] = 1;
				++devicesToUnlock;
			}
		}
	}

	if( devicesToUnlock == 0 ) {
		fprintf( stderr, "Error: No decryptable devices found!\n" );
		errorExit = 1;
	}

	if( errorExit ) {
		free( unlockList );
		crypttab_free( &crypttab );

		return 1;
	}

	if( !mlockall( MCL_FUTURE ) ) {
		fprintf( stderr, "Warning: Unable to lock memory, are you root?\n" );
	}


	char password[ kPasswordSize ];
	int passwordSize = 0;
	// Can't use fgets as no guarantee that characters are printable, etc
	for( int chr = 0; chr < kPasswordSize && !feof( stdin ); ++chr ) {
		int rc = fgetc( stdin );
		if( rc == EOF )  {
			passwordSize = chr;
			break;
		} else {
			password[ chr ] = (unsigned char) rc;
		}
	}
	
	crypttab_lookupblkids( &crypttab );
	
	for( int entryIdx = 0; entryIdx < crypttab.size; ++entryIdx ) {
		struct crypttab_entry *entry = crypttab.entries + entryIdx;

		if( !unlockList[ entryIdx ] ) continue;

		if( strncmp( kDevPath, entry->real_device, strlen( kDevPath ) ) != 0 ) {
			fprintf( stderr, "Error: disk device '%s' not found\n", entry->device );
			errorExit = 1;
			break;
		}

		// Right, now we have something to unlock
		char *path = "/sbin/cryptsetup";
		char *args[] = {
			path,
			"luksOpen",
			entry->real_device,
			entry->mapper,
			NULL
		};

		int result = runchild( password, passwordSize, path, args );
		if( result ) {
			fprintf( stderr, "Could not open %s (%s)\n", entry->mapper, entry->real_device );
			errorExit = 1;
			break;
		}
	}

	crypttab_free( &crypttab );
	free( unlockList );

	// Clear any record of password from RAM
	memset( password, '\0', kPasswordSize );

	if( !errorExit ) {
		// Fork ourselves and run the cleanup script
		// Fork so that our return code isn't affected by the script
		if( fork() == 0 ) {
			system( "/sbin/unlock-reap-success" );
		}
	}

	return errorExit;
}

	

	
