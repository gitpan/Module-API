# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package Module::API::Message;
use base 'Module::API::Base';

use strict;
use warnings;

use Data::Dumper;
use Carp;
use Storable;
use List::Util qw( first );
use Scalar::Util qw( weaken );

use Module::API::Response;
use Module::API::Handler;
use Module::API::Payload;

use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use HTTP::Status;

sub _extra_config_fields {
    my $class = shift;
    my $type  = $class->_what_am_i;

    my %field;
    $field{request_name} = 1;
    return \%field;
}

=head2 payload

FIXME

=cut

sub payload {
    my $self = shift;
    return $$self{payload} ||= $self->_create_payload;
}

sub _create_payload {
    my $self = shift;
    my $type = $self->_what_am_i;

    my $p =
      Module::API::Payload->new( api_class => $self->config('api_class'), );

    $p->encoding( $self->config('encoding') );

    my $payload_hashref = {
        "${type}_config" => $self->config,
        "${type}_data"   => $self->data,
    };

    $$payload_hashref{request_config} = $self->request->config_copy
      if $self->_what_am_i eq 'response';

    $p->as_hashref($payload_hashref);

    return $p;
}

sub set_data_from_payload {
    my $self = shift;
    my $type = $self->_what_am_i;
    my $key  = $type . "_data";

    $$self{$key} = $self->payload->as_hashref->{$key};
    return $self->data;
}

sub _what_am_i {
    my $self = shift;
    my $class = ref($self) || $self || '';
    return 'request'  if $class eq 'Module::API::Request';
    return 'response' if $class eq 'Module::API::Response';
    croak "Can't deal with class '$class'";
}

sub data {
    my $self = shift;
    my $type = $self->_what_am_i;
    my $key  = "${type}_data";

    if (@_) {
        my $data = shift;

        croak "data must be a hashref" unless ref $data eq 'HASH';

        $self->{$key} = $data;
        $self->payload->as_hashref->{$key} = $data;
    }

    # Perhaps the data is not defined and should be fetched from the
    # payload?
    if ( !defined $$self{$key} && defined $$self{payload} ) {
        $$self{$key} = $self->payload->as_hashref->{$key};
    }

    return $self->{$key} ||= {};
}

sub get_encoder_module {
    my $self     = shift;
    my $encoding = shift || $self->payload_encoding;

    my $encoder =
      first { $_->can_do_encoding($encoding) } $$self{parent_class}->encoders;

    croak "Could not get an encoder for '$encoding'" unless $encoder;
    return $encoder;
}

=head2 as_http_message

    my $string = $api_request->as_http_message;

=cut

sub as_http_message {
    my $self = shift;
    my $type = $self->_what_am_i;

    croak "Cannot create a http request without a server specified"
      unless $self->config('server_url');

    # create the message.
    my $msg =
      $type eq 'request'
      ? HTTP::Request->new( POST => $self->config('server_url') )
      : HTTP::Response->new(RC_OK);

    my %headers = $self->http_headers;
    $msg->header(%headers);

    $msg->content( $self->payload->as_string );
    $msg->content_length( length $self->payload->as_string );

    return $msg;
}

=head2 http_headers

    %headers = $api_request->http_headers;

=cut

sub http_headers {
    my $self = shift;
    my $type = $self->_what_am_i;

    # create the headers.
    my $config = $self->config_copy;

    my $header_prefix = uc "X-MODULE-API-$type-CONFIG-";

    $$config{ uc $header_prefix . $_ } = delete $$config{$_} for keys %$config;

    return wantarray ? %$config : $config;
}

sub api_object {
    my $self = shift;

    if (@_) {
        $$self{api_object} = shift;

        # Weaken this ref so that the checks on the queue being
        # destroyed happen correctly.
        weaken( $$self{api_object} );
    }

    return $$self{api_object};
}

1;
