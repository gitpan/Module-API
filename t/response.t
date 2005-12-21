# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

use Test::More 'no_plan';

use_ok 'Module::API::Response';
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

{    # Test the basic Module::API response stuff.
    my $api_response = Module::API::Response->new(%default);
    ok $api_response, "Got an Module::API response object";
    is $api_response->config($_), $default{$_}, "got correct $_"
      for sort keys %default;
}

{    # Test that extra args cause error.
    my %copy = %default;
    $copy{foo} = 'bar';
    my $api_response = eval { Module::API::Response->new(%copy) };
    ok !$api_response, "response not created with extra arg";
    like $@, qr{^Not a valid config field: 'foo' at}, "error correct";
}

{    # check that the payload has the correct structure
    my $res = Module::API::Response->new(%default);
    my $req = Module::API::Request->new(%default);
    $res->request($req);
    my $hr = $res->payload->as_hashref;

    my @keys     = sort keys %$hr;
    my @expected = sort qw(request_config response_data response_config);

    # Check that only the fields expeted exist.
    is_deeply \@keys, \@expected, "correct fields in payload.";

    # Check that all fields have a hashref as their values.
    is ref( $$hr{$_} ), 'HASH', "field '$_' is a hashref" for sort keys %$hr;
}

{    # Test that the encoding works
    my $res = Module::API::Response->new(%default);
    my $req = Module::API::Request->new(%default);
    $res->request($req);

    ok $res->payload->as_hashref( { foo => 'bar' } ), "change the payload";
    ok $res->payload->encoding('yaml'), "change the encoding";

    use YAML;
    is $res->payload->as_string, YAML::Dump( { foo => 'bar' } ),
      "check encoding is correct";
}

{    # check that values set to the data are reflected in the payload.
    my $res = Module::API::Response->new(%default);
    my $req = Module::API::Request->new(%default);
    $res->request($req);

    is $res->data, $res->payload->as_hashref->{response_data},
      "Check that the data and payload match.";

    my $hr = { foo => 'bar' };
    ok $res->data->{test} = $hr, "change the data";
    is $res->payload->as_hashref->{response_data}{test}, $hr,
      "change reflected";
}

{    # check that the response can be made into a string on demand.
    my $res = Module::API::Response->new(%default);
    my $req = Module::API::Request->new(%default);
    $res->request($req);

    $res->data->{foo} = [ 'bar', 'baz' ];

    ok my $msg = $res->as_http_response, "Got a msg";
    isa_ok $msg, 'HTTP::Response';

    my $expected = expected_msg();
    my $actual   = $msg->as_string;

    # Take the status line off - formatting varies.
    $actual =~ s{^200.*$}{200 OK}m;

    is $actual, $expected, "msg is correct";
    use Test::LongString;
    is_string $actual, $expected, "msg is correct";
}

##############################################################################
sub expected_msg {
    return << 'END_MSG';
200 OK
Content-Length: 305
X-MODULE-API-RESPONSE-CONFIG-API-CLASS: Module::API
X-MODULE-API-RESPONSE-CONFIG-ENCODING: yaml
X-MODULE-API-RESPONSE-CONFIG-REQUEST-NAME: echo
X-MODULE-API-RESPONSE-CONFIG-SERVER-URL: http://test.com/api
X-MODULE-API-RESPONSE-CONFIG-TOKEN: xXxxXx

---
request_config:
  api_class: Module::API
  encoding: yaml
  request_name: echo
  server_url: http://test.com/api
  token: xXxxXx
response_config:
  api_class: Module::API
  encoding: yaml
  request_name: echo
  server_url: http://test.com/api
  token: xXxxXx
response_data:
  foo:
    - bar
    - baz
END_MSG
}
