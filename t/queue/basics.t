# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

# get the modules loaded.
use_ok 'Module::API';
use_ok 'Module::API::Queue';

# check that all the methods are there.
can_ok 'Module::API', qw( send_nb queue );
can_ok 'Module::API::Queue',
  qw( new slots to_send_count in_progress_count to_return_count
  total_count add poke next_response );

# create a new queue from the api object.
my $api   = Module::API->new();
my $queue = $api->queue;
ok $queue,     "got a queue";
isa_ok $queue, 'Module::API::Queue';
is $api->queue, $queue, "Got the same queue again";

# check that the counts are zero
is $queue->to_send_count,     0, "to_send_count == 0";
is $queue->in_progress_count, 0, "in_progress_count == 0";
is $queue->to_return_count,   0, "to_return_count == 0";
is $queue->total_count,       0, "total_count == 0";

# Check that 'next_response' returns 'undef'.
is $queue->next_response, undef, "next_response gives 'undef'";

# check that the default slots is 20 and can be changed.
is $queue->slots, 20, "default is correct";
is $queue->slots(123), 123, "slots can be changed.";
is $queue->slots, 123, "changes remain";

1;

