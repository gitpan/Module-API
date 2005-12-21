# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package TestAPI;
use base 'Module::API';

sub init {
    my $self = shift;

    $self->config( 'server_url', 'http://localhost/1/2/3' );
    $self->config( 'encoding',   'yaml' );
    $self->config( 'token',      'test token' );

    return $self;
}

1;
