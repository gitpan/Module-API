# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

# get the modules loaded.
use_ok 'Module::API';

{
    my $api = Module::API->new( server_url => 'http://localhost:12345/' );
    ok $api, "got the api object";

    # Destroy an empty queue - no errors.
    my $queue = $api->queue;
    is $queue->total_count, 0, "queue is empty";
    1;
}

is $@, '', "no error produced";

{
    my $warn = '';
    local $SIG{__WARN__} = sub { $warn .= join "", @_ };

    {
        my $api = Module::API->new( server_url => 'http://localhost:12345/' );
        ok $api, "got the api object";

        # Start the server.
        my $pid = $api->server->background;
        sleep 1;
        END { ok $pid && kill( 9, $pid ), "killed the server on '$pid'"; }

        # Send a non_blocking request.
        $api->queue->slots(1);
        ok $api->send_nb( 'echo', { foo => 'bar' } ), "send a nb_request";
        is $api->queue->total_count, 1, "It is in the system";
    }

    like $warn, qr{Queue destroyed but not empty}, "correct warning";
}

1;

