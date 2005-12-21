# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

use_ok 'Module::API::Base';

my $api = Module::API::Base->_base_object;
bless $api, 'Module::API::Base';

my $expected = {
    api_class  => 'Module::API::Base',
    encoding   => '',
    server_url => '',
    token      => '',
};

{    # check that the config method works.
    my $config = $api->config;
    is ref $config, 'HASH', "config returns a hash";
    is_deeply $config, $expected, "values are correct";
}

{    # Test setting some values.
    for ( keys %$expected ) {

        my $value = "$_ " . rand;
        $$expected{$_} = $value;

        is $api->config( $_, $value ), $value, "Set value for $_";
        is $api->config($_), $value, "Got correct value for $_";
    }
}

{    # check that the config method works.
    my $config = $api->config;
    is ref $config, 'HASH', "config returns a hash";
    is_deeply $config, $expected, "values are correct";
}

{    # check that bad values cannot be set or retrieved.
    ok !eval { $api->config('bad'); 1 }, "tried to get 'bad'";
    ok !eval { $api->config( 'bad', 'foo' ); 1 }, "tried to set 'bad'";
}

{    # check that only scalars can be set.

    my %test = (
        undef    => undef,
        hashref  => { foo => 'bar' },
        arrayref => [ 'foo', 'bar' ],
        subref   => sub { 'foo' },
    );

    ok( !eval { $api->config( 'server_url', $test{$_} ); 1 },
        "tried to set '$_'" )
      for sort keys %test;
}

# Check that the config copy is the same as the config but a different
# hashref.
{
    my $config      = $api->config;
    my $config_copy = $api->config_copy;

    is_deeply $config, $config_copy, "contents are the same";
    isnt $config,      $config_copy, "but different hashrefs";
}

# Check that the extra fields works as expected.
{
    my $eft = ExtraFieldsTest->new(
        foo        => 'test foo',
        server_url => 'test server',
    );
    ok $eft, "Got the ExtraFieldsTest object";

    is $eft->config('foo'), 'test foo', "foo correct";
    ok $eft->config( 'foo', 'foo foo' ), "set 'foo'";
    is $eft->config('foo'), 'foo foo', "foo correct";

    is $eft->config('bar'), 'default bar value', "bar works too";
}

# Check that dodgy values can't be set using 'new';
{
    my $eft = eval {
        ExtraFieldsTest->new( bad => 'test', );
        1;
    };

    is $eft, undef, "object not created";
    like $@, qr{^Not a valid config field: 'bad' at t/config.t line \d+$},
      "got the error";
}

##############################################################################

package ExtraFieldsTest;
use base 'Module::API::Base';

sub _extra_config_fields {
    return { foo => '', bar => 'default bar value' };
}

1;
