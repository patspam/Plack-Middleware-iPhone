#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Plack::Middleware::iPhone' ) || print "Bail out!
";
}

diag( "Testing Plack::Middleware::iPhone $Plack::Middleware::iPhone::VERSION, Perl $], $^X" );
