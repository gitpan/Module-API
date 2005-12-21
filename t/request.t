# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';
use Test::LongString;

use_ok 'Module::API::Request';
use Module::API;

# Set up the payload with some interesting data.
my $payload = {
    foo   => 'bar',
    array => [ 'a', [ 'b', 'c' ], { d => 'e' }, ],
    hash    => { a => 'b' },
    unicode => "\x{263a}",
};

my %default = (
    server_url   => 'http://test.com/api',
    encoding     => 'yaml',
    request_name => 'echo',
    token        => 'xXxxXx',
    api_class    => 'Module::API',
);

{    # Test the basic Module::API request stuff.
    my $api_request = Module::API::Request->new(%default);
    ok $api_request, "Got an Module::API request object";
    is $api_request->config($_), $default{$_}, "got correct $_"
      for sort keys %default;
}

{    # Test check that it works from Module::API as well.
    my %copy = %default;

    my $request_name = delete $copy{request_name};
    delete $copy{api_class};

    my $api = Module::API->new(%copy);
    ok $api, "Got an Module::API object";

    my $api_request = $api->create_request( request_name => $request_name );
    ok $api_request, "Got an Module::API request object";
    is $api_request->config($_), $default{$_}, "got correct $_"
      for sort keys %default;
}

{    # Test that extra args cause error.
    my %copy = %default;
    $copy{foo} = 'bar';
    my $api_request = eval { Module::API::Request->new(%copy) };
    ok !$api_request, "request not created with extra arg";
    like $@, qr{^Not a valid config field: 'foo' at}, "error correct";
}

{    # check that the payload has the correct structure
    my $r  = Module::API::Request->new(%default);
    my $hr = $r->payload->as_hashref;

    my @keys     = sort keys %$hr;
    my @expected = sort qw(request_data request_config);

    # Check that only the fields expeted exist.
    is_deeply \@keys, \@expected, "correct fields in payload.";

    # Check that all fields have a hashref as their values.
    is ref( $$hr{$_} ), 'HASH', "field '$_' is a hashref" for sort keys %$hr;
}

{    # Test that the encoding works
    my $r = Module::API::Request->new(%default);

    ok $r->payload->as_hashref( { foo => 'bar' } ), "change the payload";
    ok $r->payload->encoding('yaml'), "change the encoding";

    use YAML;
    is $r->payload->as_string, YAML::Dump( { foo => 'bar' } ),
      "check encoding is correct";
}

{    # check that values set to the data are reflected in the payload.
    my $r = Module::API::Request->new(%default);
    is $r->data, $r->payload->as_hashref->{request_data},
      "Check that the data and payload match.";

    my $hr = { foo => 'bar' };
    ok $r->data->{test} = $hr, "change the data";
    is $r->payload->as_hashref->{request_data}{test}, $hr, "change reflected";
}

{    # check that the request can be made into a string on demand.
    my $r = Module::API::Request->new(%default);
    $r->data->{foo} = [ 'bar', 'baz' ];

    ok my $msg = $r->as_http_request, "Got a msg";
    isa_ok $msg, 'HTTP::Request';

    my $expected = expected_msg();
    my $actual   = $msg->as_string;
    is $actual,        $expected, "msg is correct";
    is_string $actual, $expected, "msg is correct";
}

##############################################################################
sub expected_msg {
    return << 'END_MSG';
POST http://test.com/api
Content-Length: 174
X-MODULE-API-REQUEST-CONFIG-API-CLASS: Module::API
X-MODULE-API-REQUEST-CONFIG-ENCODING: yaml
X-MODULE-API-REQUEST-CONFIG-REQUEST-NAME: echo
X-MODULE-API-REQUEST-CONFIG-SERVER-URL: http://test.com/api
X-MODULE-API-REQUEST-CONFIG-TOKEN: xXxxXx

---
request_config:
  api_class: Module::API
  encoding: yaml
  request_name: echo
  server_url: http://test.com/api
  token: xXxxXx
request_data:
  foo:
    - bar
    - baz
END_MSG
}
