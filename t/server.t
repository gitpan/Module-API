# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;
use Test::More 'no_plan';

use Module::API;

use_ok 'Module::API::Server';

use Test::WWW::Mechanize;
use Data::Dumper;

my $port     = 12345;
my $url_root = "http://localhost:$port/";

# Create an api object.
my $api = Module::API->new(
    server_url => $url_root,
    encoding   => 'yaml'
);
ok $api, "Got an api object";
is $api->config('server_url'), $url_root, "correct root is set";

# Get a server instance.
my $server = $api->server;
ok $server,     "got the server";
isa_ok $server, "Module::API::Server";
is $server->port, $port, "correct port is set";

# Start the server.
my $pid = $server->background;
sleep 1;
END { ok $pid && kill( 9, $pid ), "killed server running on pid: '$pid'"; }

# check that it is running.
my $mech = Test::WWW::Mechanize->new;
$mech->get( $url_root, "can get '$url_root'" );
is $mech->status, 404, "Got the page not found";
$mech->content_like( qr{naughty}i, "got proper error" );

my $data = { foo => 'bar' };
my $response = $api->send( 'echo', $data );

ok $response, "got a response";
is_deeply $response->data, $data, "got the correct results back";

