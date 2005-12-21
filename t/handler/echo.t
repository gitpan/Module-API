# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

# Test the basic Module::API stuff.
use_ok 'Module::API';

my $api = Module::API->new;
ok $api, "Got an Module::API object";

# Set up the data with some interesting data.
my $data = {
    foo   => 'bar',
    array => [ 'a', [ 'b', 'c' ], { d => 'e' }, ],
    hash    => { a => 'b' },
    unicode => "\x{263a}",
};

# Do the simplest request - echo.
my $response = $api->send( 'echo', $data );
ok $response,     "got a response";
isa_ok $response, 'Module::API::Response';

# Check that the result is the data echoed back.
is_deeply $response->data, $data, "checking the result";
