#include <stdio.h>
#include <linux/limits.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "crypttab.h"

#include <blkid/blkid.h>

char *crypttab_skipwhitespace( char *line );
char *crypttab_parsefield( char *line, char *dest );
struct crypttab_entry *crypttab_parseline( char *line );
int crypttab_resize( struct crypttab *list, int newsize );

char *crypttab_skipwhitespace( char *line )
{
	if( line == NULL ) return NULL;

	for( ; line[ 0 ] != '\0' && isspace( *line ); ++line ) {
		if( line[ 0 ] == '\0' ) return NULL;
	}

	return line;
}

char *crypttab_parsefield( char *line, char *dest )
{
	int chr = 0;

	line = crypttab_skipwhitespace( line );
	if( line == NULL ) {
		dest[ 0 ] = '\0';
		return NULL;
	}

	for( ; line[ chr ] != '\0' && !isspace( line[ chr ] ); ++chr ) {
		dest[ chr ] = line[ chr ];

		if( chr >= (PATH_MAX - 1 ) ) break;
	}

	dest[ chr ] = '\0';

	return (line + chr );
}

struct crypttab_entry *crypttab_parseline( char *line )
{
	struct crypttab_entry *entry = NULL;
	
	line = crypttab_skipwhitespace( line );
	if( line == NULL ) {
		return NULL;
	}

	
	if( line[ 0 ] == '#' || line[ 0 ] == '\0' ) {
		return NULL;
	}

	entry = calloc( 1, sizeof( struct crypttab_entry ) );
	if( !entry ) return NULL;

	entry->real_device = NULL;

	line = crypttab_parsefield( line, entry->mapper );
	line = crypttab_parsefield( line, entry->device );
	line = crypttab_parsefield( line, entry->keyfile );

	// Normalise data
	if( entry->keyfile[ 0 ] == '\0' ) {
		strncpy( entry->keyfile, "none", PATH_MAX );
	}

	return entry;
}

void crypttab_freeentry( struct crypttab_entry *entry )
{
	if( entry->real_device ) {
		free( entry->real_device );
	}
}

int crypttab_resize( struct crypttab *list, int newSize )
{
	if( list->entries ) {
		struct crypttab_entry *newList =
			realloc( list->entries, sizeof( struct crypttab_entry ) * newSize );
		if( newList ) {
			list->entries = newList;
			list->size = newSize;
		} else {
			crypttab_free( list );
		}		
	} else {
		list->entries = malloc( sizeof( struct crypttab_entry ) );
		if( !list->entries ) {
			list->size = 0;
		}
		list->size = newSize;
	}

	return list->size;
}

void crypttab_free( struct crypttab *list )
{
	for( int entry = 0; entry < list->size; ++entry ) {
		crypttab_freeentry( list->entries + entry );
	}

	free( list->entries );
	list->size = 0;
	list->entries = NULL;
}


struct crypttab crypttab_parse( const char const*filename )
{
	struct crypttab list;
	char lineBuf[ PATH_MAX ];
	FILE *file = NULL;

	list.size = 0;
	list.entries = NULL;

	file = fopen( filename, "r" );
	if( !file ) return list;

	while( !feof( file ) ) {
		struct crypttab_entry *entry = NULL;

		fgets( 	lineBuf, PATH_MAX, file );
		if( feof( file ) ) break;
		
		entry = crypttab_parseline( lineBuf );

		if( entry ) {
			if( crypttab_resize( &list, list.size + 1 ) == 0 ) {
				return list;
			}

			list.entries[ list.size - 1 ] = *entry;	
		}
	}

	return list;
}

void crypttab_lookupblkids( struct crypttab *list )
{
	for( int entryIdx = 0; entryIdx < list->size; ++entryIdx ) {
		struct crypttab_entry *entry = list->entries + entryIdx;

		entry->real_device = blkid_evaluate_tag( entry->device, NULL, NULL );
	}
}

