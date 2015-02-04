#ifndef _CRYPTTAB_H_
#define _CRYPTTAB_H_

#include <linux/limits.h>

struct crypttab_entry {
	char mapper[ PATH_MAX ];
	char device[ PATH_MAX ];
	char *real_device;
	char keyfile[ PATH_MAX ];
};

struct crypttab {
	struct crypttab_entry *entries;
	int size;
};

struct crypttab crypttab_parse( const char const*filename );
void crypttab_lookupblkids( struct crypttab *list );
void crypttab_free( struct crypttab *list );
void crypttab_freeentry( struct crypttab_entry *entry );

#endif

