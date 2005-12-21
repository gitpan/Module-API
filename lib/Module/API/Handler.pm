# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Module::API::Handler;

use Data::Dumper;
use Carp;
use List::Util qw(first);

use Module::API::Response;

=head2 process

    $api_response = Module::API::Handler->process( $api_request );

Given an C<$api_request> the correct plugin is found, the request
processed and a response object created.

=cut

sub process {
    my $class   = shift;
    my $request = shift;

    my $response = Module::API::Response->new( %{ $request->config_copy } );
    $response->request($request);

    # Work out which handler to use.
    my $request_name = $request->config('request_name');

    my $plugin =
      first { $_->can_do_request($request_name) }
      $request->config('api_class')->plugins();

    # No plugin found? then croak for now.
    croak "Can't do request '$request_name'" unless $plugin;

    # Otherwise do the request.
    my $result = $plugin->process( $request, $response );

    # Add the results to the response and return it.
    return $response;
}

1;
