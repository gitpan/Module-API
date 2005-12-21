# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Module::API::Response;
use base 'Module::API::Message';

use Data::Dumper;
use Carp;

sub request {
    my $self = shift;
    $$self{request} = shift if @_;

    croak "No request has been set yet"
      unless $$self{request};

    return $$self{request};
}

=head2 as_http_response

    my $string = $api_response->as_http_response;

=cut

sub as_http_response {
    my $self = shift;
    return $self->as_http_message;
}

1;
