#!/usr/bin/perl -w

# Load test the Archive::Builder module

use strict;
use lib ();
use UNIVERSAL 'isa';
use File::Spec::Functions ':ALL';
BEGIN {
	$| = 1;
	unless ( $ENV{HARNESS_ACTIVE} ) {
		require FindBin;
		chdir ($FindBin::Bin = $FindBin::Bin); # Avoid a warning
		lib->import( catdir( updir(), updir(), 'modules') );
	}
}





# Does everything load?
use Test::More 'tests' => 6;
BEGIN {
	ok( $] >= 5.005, 'Your perl is new enough' );
}

use_ok( 'Archive::Builder'             );
use_ok( 'Archive::Builder::Section'    );
use_ok( 'Archive::Builder::File'       );
use_ok( 'Archive::Builder::Generators' );
use_ok( 'Archive::Builder::Archive'    );

exit(0);
