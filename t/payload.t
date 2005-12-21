# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

use_ok 'Module::API::Payload';
use Module::API;

use YAML();
use Storable();

# Set up the payload with some interesting data.
my $payload_hashref         = { foo => 'bar', };
my $payload_yaml_string     = YAML::Dump($payload_hashref);
my $payload_storable_string = Storable::nfreeze($payload_hashref);

my $p = Module::API::Payload->new( api_class => 'Module::API' );
ok $p, "got the payload";

ok !eval { $p->as_hashref; 1 }, "No payload set yet";
like $@, qr{^No payload has been set yet}, "error correct";

is $p->encoding, undef, "No encoding has been set";
ok !eval { $p->as_string; 1 }, "croak if no encoding set";
like $@, qr{^No payload has been set yet}, "error correct";

# Set a payload and an encoding.
ok $p->as_hashref($payload_hashref), "set hashref";
is $p->as_hashref, $payload_hashref, "hashref correct";
ok !eval { $p->as_string; 1 }, "croak if no encoding set";
like $@, qr{No encoding has been set}, "encoding error correct";

# Set the encoding and check that the string produced is correct.
is $p->encoding('yaml'), 'yaml', "set encoding";
is $p->encoder, 'Module::API::Encoder::YAML', 'encoder works';
is $p->as_string, $payload_yaml_string, "as_string correct";

# Change the encoding and check that the string is still correct.
ok $p->encoding('storable'), "set encoding to storable";
is $p->encoding, 'storable', "got storable";
is $p->encoder, 'Module::API::Encoder::Storable', 'encoder works';
is $p->as_string, $payload_storable_string, "as_string correct";

# Check that the decoding works too.
ok $p->clear, "clear the object";
ok $p->encoding('storable'), "set the encoding";
ok $p->as_string($payload_storable_string), "set the string";
is_deeply $p->as_hashref, $payload_hashref, "get the hashref";

# Check that the decoding works too.
ok $p->clear, "clear the object";
ok $p->encoding('storable'), "set the encoding";
ok $p->as_string($payload_storable_string), "set the string";
ok $p->encoding('yaml'), "change the encoding to yaml";
is_deeply $p->as_hashref, $payload_hashref, "get the hashref";

# Everytime the hashref is asked for it might get changed - so make
# sure that the string is cleared so that the two can not get out oy
# step.
{
    my $string  = $p->as_string;
    my $hashref = $p->as_hashref;
    $$hashref{new} = 'values';
    isnt $p->as_string, $string, "Check that the string changed";
}
