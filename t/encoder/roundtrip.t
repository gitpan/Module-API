# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use File::Slurp;

use Test::More;

# Get the encoders and check that we know about them all.
my @encoders_found = sort map {
    s{^lib/(.*)\.pm$}{$1};
    s{/}{::}g;
    $_
} <lib/Module/API/Encoder/*.pm>;

{    # work out how many tests there are.
    my %tests              = test_payloads();
    my $number_of_encoders = scalar @encoders_found;

    my $tests_per_encoder = 0    # ---
      + 1                        # the modules found check
      + 1                        # the message line
      + 1                        # the use_ok line
      + $number_of_encoders      # the 'can_do_..' checks
      + ( 2 * scalar keys %tests )    # the roundtrips
      ;

    plan tests => $number_of_encoders * $tests_per_encoder;
}

# These are the encoders that are known about.
my %encoder = (
    'Module::API::Encoder::YAML'     => 'yaml',
    'Module::API::Encoder::Storable' => 'storable',
);

# check that the encoders found match those known.
ok exists $encoder{$_}, "Will test for '$_'" for @encoders_found;

foreach my $encoder_module ( sort keys %encoder ) {

    ok 1, "-" x 10 . " Running tests on '$encoder_module'. " . "-" x 10;

    my $encoder_name = $encoder{$encoder_module};

    # Check that it can be used.
    use_ok $encoder_module;

    # Check that it only answers to the correct name.
    my %expected = map { $_ => 0 } values %encoder;
    $expected{$encoder_name} = 1;

    is $encoder_module->can_do_encoding($_), $expected{$_},
      "want '$expected{$_}' for '$encoder_module->can_do_encoding('$_')'"
      for sort keys %expected;

    # Get the payload to test.
    my %tests = test_payloads();

    while ( my ( $name, $payload ) = each %tests ) {

        die "ARGHH! - payload must be a hashref" unless ref($payload) eq 'HASH';

        # Check that the decoding works too.
        my $returned_encoded = $encoder_module->encode($payload);
        my $returned_decoded = $encoder_module->decode($returned_encoded);

        ok !ref($returned_encoded), "encoded data is a scalar for '$name'";
        is_deeply $returned_decoded, $payload, "roundtripping '$name' data";
    }
}

sub test_payloads {
    return (
        'empty hashref' => {},

        'collection of all' => {
            foo   => 'bar',
            array => [ 'a', [ 'b', 'c' ], { d => 'e' }, ],
            hash    => { a => 'b' },
            unicode => "\x{263a}",
        },

        'this tests file contents' =>
          { file => scalar read_file('t/encoder/roundtrip.t') },

        'deep array nesting' => {
            arrays => [ [ [ [ [ 'foo', [ [ [ [ ['bar'] ] ] ] ], 'baz', ] ] ] ] ]
        },

        'deep hash nesting' =>
          { a => { b => { c => { d => { e => { f => 'g' } } } } } },

    );
}
