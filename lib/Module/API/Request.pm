# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package Module::API::Request;
use base 'Module::API::Message';

use strict;
use warnings;

use Data::Dumper;
use Carp;
use Storable;
use List::Util qw(first );

use Module::API::Response;
use Module::API::Handler;
use Module::API::Payload;

use LWP::UserAgent;

=head2 send

    $api_response = $api_request->send;

This sends the request, be it to a remote machine or processing it
locally. It deals with encoding the payload, making the connections
etc.

=cut

sub send {
    my $self = shift;

    #warn "here";

    # Either send this to a remote server or process it locally.
    return $self->config('server_url') eq ''
      ? $self->process_locally
      : $self->process_remotely;
}

=head2 process_locally

    $api_response = $api_request->process_locally;

This processes the request locally by handing the request over to the
Module::API::Handler which deals with it on this machine.

=cut

sub process_locally {
    my $self     = shift;
    my $response = Module::API::Handler->process($self);
    return $response;
}

=head2 process_remotely

    $api_reponse = $api_request->process_remotely();

Takes the request, serializes it and then sends it to the remote
C<server_url>. It then reads back the http response and constructs a
response object which it returns.

=cut

sub process_remotely {
    my $self = shift;

    croak "Can't process remotely without a 'server_url'"
      unless $self->config('server_url');

    my $ua = LWP::UserAgent->new;

    my $http_response = $ua->request( $self->as_http_request );

    my $config       = $self->config_copy;
    my $api_response = Module::API::Response->new(%$config);

    $api_response->request($self);
    $api_response->api_object( $self->api_object );

    $api_response->payload->as_string( $http_response->content );
    $api_response->set_data_from_payload;

    my $token = $api_response->payload->as_hashref->{response_config}{token};
    $api_response->config( 'token', $token );
    $api_response->api_object->config( 'token', $token );

    return $api_response;
}

=head2 as_http_request

    my $string = $api_request->as_http_request;

=cut

sub as_http_request {
    my $self = shift;
    return $self->as_http_message;
}

1;
