# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package Module::API;
use base 'Module::API::Base';

our $VERSION = '0.01';

use strict;
use warnings;

use Carp;
use Data::Dumper;
use List::Util;
use Module::API::Request;
use Module::API::Server;
use Module::API::Queue;

# 'require' rather than 'use' so that we can decide what methods to
# create in import.
require Module::Pluggable;

sub import {
    my $class = shift;

    # Put the encoders method into the class.
    Module::Pluggable->import(
        sub_name    => 'encoders',
        package     => $class,
        require     => 1,
        search_path => [ "Module::API::Encoder", "$class\:\:Encoder" ],
    );

    # Put the encoders method into the class.
    Module::Pluggable->import(
        sub_name    => 'plugins',
        package     => $class,
        require     => 1,
        search_path => ["$class\:\:Plugin"],
    );

    return 1;
}

=head1 NAME

Module::API

=head1 WARNING

This code is still being developed. It is subject to change at any
moment. It is only being made available at this time to solicit
comments on it. If you see something you want changed please let me
know.

=head1 SYNOPSIS

In file C<MyModule::API.pm>:

    package MyAPI;
    use base 'Module::API';

    sub init {
      $self = shift;
      $self->api_server( 'http://my.server.com/api-listner' );
    }

In some other code:

    use MyAPI;
    my $api = MyAPI->new;

    # Send an API request to be handled on the remote server by a
    # plugin under 'MyAPI::Handler::...';
    my $response = $api->send( 'request_name', $payload_hashref );

=head1 METHODS

=head2 new

    $api = Module::API->new;

Get a new api object that is used to send and recieve the Module::API
requests. Can also be used to set settings at start up:

    $api = Module::API->new(
        token    => 'abcdefghijklmnopqrst',
        server_url   => 'http://api.example.com/api',
        encoding => 'xml',
    );

=cut

sub new {
    my $class = shift;
    my $self  = bless $class->_base_object, $class;
    my %args  = @_;

    # Apply all the args that are allowed.
    for (qw( server_url encoding token )) {
        next unless exists $args{$_};
        $self->config( $_, delete $args{$_} );
    }

    # check that there are no values unused.
    croak(  "The following arguments are not allowed: '"
          . join( "', '", sort keys %args )
          . "'" )
      if keys %args;

    # Set values in config and then apply defaults if needed.
    $self->init;
    $self->set_defaults;

    return $self;
}

=head2 init

    package MyAPI;
    use base 'Module::API';

    sub init {
        my $self = shift;

        my $token = load_token_from_file_or_something();
        $self->config( 'token', $token );

        return 1;
    }

C<init> is a method that you should override to initure your API
object. It is called by C<new> after the object has been created and
the values passed in have been assigned. After it has returned
C<set_defaults> is called.

=cut

sub init { 1; }

=head2 set_defaults

    $api->set_defaults;

Looks at what the current settings are and then changes other settings
that are not set to the correct defaults:

    token    => ''
    server_url       => ''
    encoding => 'storable'

=cut

sub set_defaults {
    my $self = shift;

    $self->config->{token}      ||= '';
    $self->config->{server_url} ||= '';
    $self->config->{encoding}   ||= 'storable';

    return 1;
}

=head1 Module::API requests

There are three ways in which the API requests can be handled -
locally, remotely and non-blocking remotely:

=head2 local requests

    $api->api_server( '' );
    $response = $api->send( 'request_name', \%payload );

Local requests are made to handlers on the local machine. This happens
by default if C<api_server> is an empty string. The advantage to local
requests is the low overhead as that there is no encoding or decoding
or the payload.

=head2 remote requests

    $api->api_server( 'http://api.exampe.com/api-listener' );
    $response = $api->send( 'request_name', \%data );

Remote requests are done over the network to a remote machine that is
listening for them. The response is returned when it is available.

=cut

sub send {
    my $self         = shift;
    my $request_name = shift;
    my $data         = shift || {};

    croak "Expecting a hashref" unless ref($data) eq 'HASH';

    # Create a new request and send it - will return the response to
    # the caller.
    my $request = $self->create_request( request_name => $request_name, )
      || croak "Could not create a request for '$request_name'";

    $request->data($data);

    my $response = $request->send;

    # Capture the returned session_token - should really be done in a
    # hook.
    $self->config( 'token', $response->config('token') );

    return $response;
}

sub send_nb {
    my $self         = shift;
    my $request_name = shift;
    my $data         = shift || {};

    croak "Expecting a hashref" unless ref($data) eq 'HASH';

    # Create a new request and send it - will return the response to
    # the caller.
    my $request = $self->create_request( request_name => $request_name, )
      || croak "Could not create a request for '$request_name'";

    $request->data($data);

    return $self->queue->add($request);
}

=head2 non-blocking remote requests

    $api->api_server('http://api.exampe.com/api-listener');
    $api->queue->add( 'request_name_1', \%payload_1 );
    $api->queue->add( 'request_name_2', \%payload_2 );

    while ( $api->queue->requests_queued ) {

        # check if a request has been completed
        if ( my $response = $api->queue->get_a_ready_response ) {

            # deal with the returned payload
            ...;
            next;
        }

        # do something whilst the requests are processed.
        ...;
    }

The problem with the remote request made using C<$api->do()> is that
it is blocking - control is not returned to the code until the
response has been returned. In many sitations this will not be a
problem but if you are writing an application that is interactive or
that needs to make several requests in parallel then this is not
ideal - especially if the API requests take a long time.

In cases like this you will want to use the request queue - see
L<Module::API::Queue> for more details. In summary you create requests
that are added to the queue. These requests are then added to an
L<IO::Select> object which is then managed. All of this is abstracted
from you so you need only add the requests and occasionally check if
any have completed and then process them.

CAVEAT: Some planning may be required as the order that the responses
will be returned in is not the order in which they are made. If you
make one slow request and then a fast one you will most likely get the
fast response back first. As the original request is available in the
response you will be able to work out what to do.

=head2 create_request

    $api_request = $api->create_request(
        request_name => $request_name,
    );

Creates a request. Settings are taken from the C<$api> object if they
are not specified as arguments. Gennerally you will want to use the
calling form C<$api->request_name> mentioned above though unless you
really want access to the request object.

=cut

sub create_request {
    my $self = shift;
    my %args = @_;

    my $config_copy = $self->config_copy;

    my $req = Module::API::Request->new(
        request_name => $args{request_name},
        %$config_copy,
    );

    $req->api_object($self);

    return $req;
}

=head2 request_from_params

    $api_request = $api->request_from_params( \%params );

=cut

sub request_from_params {
    my $self   = shift;
    my $params = shift;

    # Decode the payload.
    my $encoder = $self->get_encoder( $$params{payload_encoding} );
    $$params{payload} = $encoder->decode( $$params{encoded_payload} );

    # Return the request object.
    return $self->create_request(%$params);
}

=head2 encoders

    @module_names = $api->encoders;

Returns a list of encoders that can be used.

=head2 get_encoder

  $encoder_name = $api->get_encoder( 'encoding-name' );

Returns the first encoder to match the encoding given.

=cut

sub get_encoder {
    my $self     = shift;
    my $encoding = shift;

    return List::Util::first { $_->can_do_encoding($encoding) } $self->encoders;
}

=head2 server

  my $server = $api->server;

Returns a L<Module::API::Server> object that can accept and process
the API calls of C<$api>. Creates the server if needed.

=cut

sub server {
    my $self = shift;

    return $$self{_server} if $$self{_server};

    my $config = $self->config_copy;
    return $$self{_server} ||= Module::API::Server->new(%$config);
}

=head2 queue

    my $api_queue = $api->queue;

Creates if needed a queue and returns it. See L<Module::API::Queue>
for more details.

=cut

sub queue {
    my $self = shift;
    croak "argh!" unless ref $self;
    return $$self{api_queue} ||= Module::API::Queue->new;
}

1;

