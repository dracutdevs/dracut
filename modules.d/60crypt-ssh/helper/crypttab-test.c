#include <stdio.h>
#include <string.h>

#include "crypttab.h"

const static int numExpectedResults = 4;
const static struct crypttab_entry expectedResults[ 4 ] = {
	{"luks-b88c3187-3abd-4eb6-810e-3679c912902e", "UUID=b88c3187-3abd-4eb6-810e-3679c912902e", NULL, "none"},
	{"luks-e3967355-5de9-4150-bf47-5c5d88c660d2", "UUID=e3967355-5de9-4150-bf47-5c5d88c660d2", NULL, "none"},
	{"luks-970223b4-62b6-400a-b0ac-74405ca9668d", "/dev/mapper/raid-array-1", NULL, "/etc/mykey" },
	{"moo", "bar",	NULL, "baz" }
};

int check_string( const char *name, const char*reference, const char*test )
{
	if( strcmp( reference, test ) != 0 ) {
		printf( "Mismatch: %s, expected %s got %s\n", name, reference, test );
		return 0;
	}
	return 1;
}

int compare_entries( const struct crypttab_entry *reference, const struct crypttab_entry *test )
{
	return check_string( "mapper", reference->mapper, test->mapper ) &&
	       check_string( "device", reference->device, test->device ) &&
	       check_string( "keyfile",reference->keyfile, test->keyfile );
}
	

int main( int argc, char **argv )
{
	struct crypttab crypttab = crypttab_parse( "./crypttab-test-data" );

	int testsPassed = 0;
	int testsToPass = 1 + numExpectedResults;

	if( crypttab.size != numExpectedResults ) {
		printf( "Did not get the right number of entries! Got %i, expected %i\n", crypttab.size, numExpectedResults );
	} else {
		testsPassed ++;
	}

	for( int line = 0; line < crypttab.size && line < numExpectedResults; ++line ) {
		testsPassed += compare_entries( &expectedResults[ line ], &crypttab.entries[ line ] );
	}

	printf( "Tests %i/%i passed\n", testsPassed, testsToPass );

	if( testsPassed == testsToPass ) {
		printf( "PASSED\n" );
		return 0;
	} else {
		printf( "FAILED\n" );
		return 255;
	}
}




