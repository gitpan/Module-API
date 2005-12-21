# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

package Module::API::Encoder::YAML;

use strict;
use warnings;

use YAML ();
use Carp;

=head1 NAME

Module::API::Encoder::YAML - encode the payload using L<YAML>.

=cut

sub can_do_encoding {
    my ( $class, $encoding ) = @_;
    return 1 if defined $encoding && $encoding eq 'yaml';
    return 0;
}

sub encode {
    my ( $class, $data_ref ) = @_;
    croak "This is not a hashref" unless ref $data_ref eq 'HASH';
    return YAML::Dump($data_ref);
}

sub decode {
    my ( $class, $encoded ) = @_;
    croak "This is not a scalar" if ref $encoded;
    my $data = YAML::Load($encoded);
    return $data;
}

1;
