# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/t_lib';
use_ok 'TestAPI';

# Get the API object.
my $api = TestAPI->new;

# Set the session_token to a known state.
$api->config( 'token',      0 );
$api->config( 'server_url', '' );
is $api->config('token'), 0, "session token is '0'";

# Call the 'increment_token' API call.
ok $api->send( 'increment_token', {} ), "Call the increment token API call";
is $api->config('token'), 1, "session token is '1'";

# Set the server_url
$api->config( 'server_url', 'http://localhost:12345/' );

# Start a server.
my $pid = $api->server->background;
sleep 1;
END { ok $pid && kill( 9, $pid ), "killed the server on '$pid'"; }

# Call the 'increment_token' API call over net.
ok $api->send( 'increment_token', {} ), "Call the increment token API call";
is $api->config('token'), 2, "session token is '2' after send over net";

# Call the 'increment_token' API call using a non blocking request.
ok $api->send_nb( 'increment_token', {} ), "Call the increment token API call";
my $limit = 5;
while ( $limit && !$api->queue->next_response ) { sleep 1; $limit--; }
is $api->config('token'), 3, "session token is '3' after send_nb";
