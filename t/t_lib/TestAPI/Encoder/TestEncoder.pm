# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package TestAPI::Encoder::TestEncoder;

use strict;
use warnings;

=head1 NAME

Module::API::Encoder::YAML - encode the payload using L<YAML>.

=cut

sub can_do_encoding {
    my ( $class, $encoding ) = @_;
    return $encoding eq 'test-encoder' ? 1 : 0;
}

sub encode {
    my ( $class, $data_ref ) = @_;
    return 'test-encoder';
}

sub decode {
    my ( $class, $encoded ) = @_;
    return { foo => 'bar' };
}

1;
