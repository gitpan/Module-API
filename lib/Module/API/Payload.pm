# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Module::API::Payload;

use Carp;

sub new {
    my $class = shift;
    my %args  = @_;

    my $api_class = delete $args{api_class};
    croak "You need to specify an api_class" unless $api_class;

    return bless {
        api_class => $api_class,
        encoding  => undef,
        hashref   => undef,
        string    => undef,
    }, $class;
}

sub clear {
    my $self = shift;
    $$self{$_} = undef for qw(encoding string hashref);
    return 1;
}

sub api_class {
    my $self = shift;
    return $$self{api_class};
}

sub encoding {
    my $self = shift;
    return $$self{encoding} unless @_;

    my $encoding = shift;
    croak "Could not find an encoder for '$encoding'"
      unless $self->encoder($encoding);

    # Set the encoding - but first set the hashref and clear the
    # string if there was an encoding to start with.
    if ( $self->encoding
        && ( defined $$self{hashref} || defined $$self{string} ) )
    {
        $self->as_hashref;
        $$self{string} = undef;
    }

    return $$self{encoding} = $encoding;
}

sub as_hashref {
    my $self = shift;

    if (@_) {
        my $hashref = shift;
        croak "Argument must be a hashref" unless ref $hashref eq 'HASH';
        $$self{hashref} = $hashref;
        $$self{string}  = undef;
    }

    # If there is no hashref stored then create it from the string.
    if ( !defined $$self{hashref} ) {

        # If there is no string set then croak.
        croak "No payload has been set yet" unless defined $$self{string};

        $$self{hashref} = $self->_string_to_hashref;
    }

    # As the hashref could get changed clear the string.
    $$self{string} = undef;
    return $$self{hashref};
}

sub as_string {
    my $self = shift;

    if (@_) {
        my $string = shift;
        croak "Argument must be a scalar" unless ref $string eq '';
        $$self{string}  = $string;
        $$self{hashref} = undef;
    }

    # If there is a string stored then return it.
    return $$self{string} if defined $$self{string};

    # If there is no string set then croak.
    croak "No payload has been set yet" unless defined $$self{hashref};

    return $$self{string} = $self->_hashref_to_string;
}

sub _hashref_to_string {
    my $self = shift;

    croak "No encoding has been set" unless defined $self->encoding;

    return $self->encoder->encode( $self->as_hashref );
}

sub _string_to_hashref {
    my $self = shift;

    croak "No encoding has been set" unless defined $self->encoding;

    return $self->encoder->decode( $self->as_string );
}

sub encoder {
    my $self     = shift;
    my $encoding = shift || $self->encoding;

    return $self->api_class->get_encoder($encoding);
}

1;
