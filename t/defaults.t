# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

# Test the basic Module::API stuff checking that the correct defaults are
# applied.

use_ok 'Module::API';

{    # create an empty api object.

    my $api = Module::API->new;
    ok $api, "Got an Module::API object";

    my %default = (
        server_url => '',
        encoding   => 'storable',
        token      => '',
    );

    is $api->config($_), $default{$_}, "checking $_" for sort keys %default;
}

{    # create an api object for a remote server

    my $api = Module::API->new( server_url => 'http://api.example.com/api' );

    ok $api, "Got an Module::API object";

    my %default = (
        server_url => 'http://api.example.com/api',
        encoding   => 'storable',
        token      => '',
    );

    is $api->config($_), $default{$_}, "checking $_" for sort keys %default;
}

{    # create an api object for a remote server with a token and a
        # different encoding

    my %default = (
        server_url => 'http://tolk.example.com/api',
        encoding   => 'xml',
        token      => 'X' x 20,
    );

    my $api = Module::API->new(%default);

    ok $api, "Got an Module::API object";

    is $api->config($_), $default{$_}, "checking $_" for sort keys %default;
}

{    # try some bad arguments.

    my $api = eval { Module::API->new( foo => 'bar', bar => 'bam' ) };

    ok !$api, "did not get an Module::API object";
    like $@, qr{^The following arguments are not allowed: 'bar', 'foo' },
      "Got correct error";
}
