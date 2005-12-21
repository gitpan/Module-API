# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

# get the modules loaded.
use_ok 'Module::API';

my $api = Module::API->new(
    server_url => 'http://localhost:12345/',
    encoding   => 'yaml'
);
ok $api, "got the api object";

# Start the server.
my $pid = $api->server->background;
sleep 1;
END { ok $pid && kill( 9, $pid ), "killed the server on '$pid'"; }

{    # Send a blocking request.
    my $data = { test => 'blocking' };
    my $response = $api->send( 'echo', $data );
    ok $response, , "sent a blocking request";
    is_deeply $response->data, $data, "Data is correct";
}

{    # Send a non_blocking request.
    my $data = { test => 'non-blocking' };
    ok $api->send_nb( 'echo', $data ), "send a nb_request";
    is $api->queue->total_count, 1, "It is in the system";

    my $limit = 0;
    while ( $api->queue->to_return_count == 0 && $limit < 5 ) {
        $limit++;
        sleep 1;
    }

    is $api->queue->to_return_count, 1, "have 1 response to return";

    my $response = $api->queue->next_response;
    isa_ok $response, 'Module::API::Response';

    is_deeply $response->data, $data, "Data is correct";
}

1;

