# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package Module::API::Encoder::Storable;

use strict;
use warnings;
use Storable ();

=head1 NAME

Module::API::Encoder::Storable - encode the payload using L<Storable>.

=cut

sub can_do_encoding {
    my ( $class, $encoding ) = @_;
    return $encoding eq 'storable' ? 1 : 0;
}

sub encode {
    my ( $class, $data_ref ) = @_;
    return Storable::nfreeze($data_ref);
}

sub decode {
    my ( $class, $encoded ) = @_;
    my $data = Storable::thaw($encoded);
    return $data;
}

1;
