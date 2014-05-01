use Test::More;
use strict;

use_ok( "Image::Leptonica" );


my $lept_version = "leptonica-1.70";
is( Image::Leptonica->version, $lept_version );

done_testing;
