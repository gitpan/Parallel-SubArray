use strict;
use Test::More tests => 5;

BEGIN { use_ok( 'Parallel::SubArray', 'par' ); }

my $sub_arrayref = [
		    sub{ sleep(1); [1] },
		    sub{ while(1){}    },
		    sub{ [ 1, {2,3} ]  },
		   ];

my $result_arrayref = par(3)->($sub_arrayref);

is( @$result_arrayref,               3,     'Result count' );
is( $result_arrayref->[0]->[0],      1,     'First result, simple structure.' );
is( $result_arrayref->[1],           undef, 'Second result, failed' );
is( $result_arrayref->[2]->[1]->{2}, 3,     'Third result, complex structure' );
