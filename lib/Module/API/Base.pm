# Copyright 2005 Edmund von der Burg
# Distributed under the same license as Perl itself.

use strict;
use warnings;

package Module::API::Base;

use Data::Dumper;
use Carp;

=head1 NAME

Module::API::Base - providing common methods to the L<Module::API> modules.

=head1 METHODS

=head2 new

    my $object = $class->new( foo => 'bar' );

Creates a new object with the values passed set to the config. Extra
fields can be permitted using C<_extra_config_fields>. See below.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    # Create the base object.
    my $self = $class->_base_object;
    bless $self, $class;

    # Assign values from the args.
    $self->config( $_, $args{$_} ) for keys %args;

    return $self;
}

=head2 config

    $config_hashref  = $api_object->config;
    $field_value     = $api_object->config('field');
    $new_field_value = $api_object->config( 'field', $value );

A somewhat magical method - returns the config hashref if called
without any arguments, returns the value of the field if called with a
field name or if called with two args sets the value and then returns
new value.

=cut

sub _is_config_field {
    my $class = shift;
    my $field = shift;

    my %allowed = (
        api_class  => 1,
        encoding   => 1,
        server_url => 1,
        token      => 1,
        %{ $class->_extra_config_fields }
    );

    return exists $allowed{$field};
}

sub _extra_config_fields { return {}; }

sub config {
    my $self = shift;
    return $$self{api_config} unless @_;

    my $field = shift;

    croak "Not a valid config field: '$field'"
      unless $self->_is_config_field($field);

    return $$self{api_config}{$field} unless @_;

    my $value = shift;

    croak "Cannot set an undef value for '$field'" unless defined $value;
    croak "Value for '$field' must be a scalar" if ref $value;

    return $$self{api_config}{$field} = $value;
    return $$self{api_config}{$field};
}

sub config_copy {
    my $self   = shift;
    my $config = $self->config;
    my %copy   = %$config;
    return \%copy;
}

=head2 _base_object

    $self = $class->_base_object;

Returns a hashref that all other Module::API::* objects can be built
on top of.

=cut

sub _base_object {
    my $class = shift;

    return {
        api_config => {
            api_class  => $class,
            encoding   => '',
            server_url => '',
            token      => '',
            %{ $class->_extra_config_fields }
        },
    };
}

1;
