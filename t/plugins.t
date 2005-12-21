# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

# The sub encoders returns a list of all the encoders that are
# available. This list can be added to by the config.

use lib 't/t_lib';
use_ok 'TestAPI';

my $api     = TestAPI->new;
my @plugins = sort $api->plugins;

my @expected = sort 'TestAPI::Plugin::TestEcho',
  'TestAPI::Plugin::IncrementToken';

is_deeply \@plugins, \@expected, "got the correct plugins";

# Check that the encoder can be found using get_encoder.
is TestAPI->get_encoder('test-encoder'), 'TestAPI::Encoder::TestEncoder',
  "got the correct encoder";
