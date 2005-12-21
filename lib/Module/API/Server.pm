# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Module::API::Server;
use base qw/HTTP::Server::Simple HTTP::Server::Simple::CGI::Environment/;

use Carp;
use Data::Dumper;
use Module::API::Base;

# catch the new call and store the data that we need.
sub new {
    my $class = shift;
    my %args  = @_;

    # FIXME - check the config here.
    my $url = $args{'server_url'};
    croak "Need to have 'server_url' set"
      unless $url;

    my $uri = URI->new($url);

    my $self = $class->SUPER::new( $uri->port );

    # Add the config to the server and return.
    $self->api_config( $_, $args{$_} ) for sort keys %args;
    return $self;
}

# Dirty but effective.
sub api_config           { return Module::API::Base::config(@_); }
sub _is_config_field     { return Module::API::Base::_is_config_field(@_); }
sub _extra_config_fields { return {}; }

sub accept_hook {

    # Clean up the environment.
    HTTP::Server::Simple::CGI::Environment::setup_environment;
    return 1;
}

sub handler {
    my ($self) = @_;

    # Read stdin.
    my $post = '';
    if ( my $length = $ENV{'CONTENT_LENGTH'} ) {
        read( STDIN, $post, $length );
    }

    my %api_header =
      map { my $key = lc $_; $key =~ s{^.*_config_}{}; $key => $ENV{$_}; }
      grep { m{^HTTP_X_MODULE_API_REQUEST_CONFIG_} } keys %ENV;

    # Check that the api_class is the same as ours. Do this with a 404
    # error.
    return error_404( "api_class not found in header or wrong.\n\n"
          . Dumper { api_header => \%api_header, content => $post } )
      unless $api_header{api_class}
      && $api_header{api_class} eq $self->api_config('api_class');

    # Create a request object.
    my $api_request = Module::API::Request->new(%api_header);
    $api_request->payload->as_string($post);
    $api_request->set_data_from_payload;

    # Process the request.
    my $api_response = $api_request->process_locally;

    # Return the response.
    # warn $api_response->as_http_response->as_string;
    print $api_response->as_http_response->content;
}

sub error_404 {
    my $input = shift;

    print << "END_CONTENT";
HTTP/1.1 404 Not Found 
Content-Type: text/html; charset=UTF-8

Naughty you! - this is not a proper API call.

$input

END_CONTENT
}

1;
