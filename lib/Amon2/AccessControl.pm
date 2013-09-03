package Amon2::AccessControl;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

use Mouse::Util ();
use Mouse;

has 'namespace' => (
    is      => 'ro',
    isa     => 'Str',
    default => __PACKAGE__ . '::Role',
);

has [qw(_success _fail)] => (
    is       => 'ro',
    isa      => 'Bool',
    required => 0,
);

has 'response' => (
    is       => 'rw',
    isa      => 'Plack::Response',
    required => 0,
);

no Mouse;

sub with {
    my ($self, $role) = @_;

    $role = ref $role ? $role : Mouse::Util::load_first_existing_class(
        $self->namespace.'::'.$role, $role
    );

    Mouse::Util::apply_all_roles($self, $role);

    return $self;
}

sub authenticate {
    my ($self, $c, $option) = @_;

    if ($option->{authenticate}) {
        my $response = $option->{authenticate}->($self, $c, $option);
        $self->response( $response ) if $response && $response->isa('Plack::Response');
    }

    return $self;
}

sub success { shift->{_success} = 1 }
sub failed  { shift->{_fail}    = 1 }

sub is_passed  {
    my $self = shift;

    return $self->_success ? 1
         : $self->_fail    ? 0
         : Carp::croak('must be called to $auth->fail or $auth->success in authenticate.');
}



1;
__END__

=encoding utf-8

=head1 NAME

Amon2::AccessControl - It's new $module

=head1 SYNOPSIS

    use Amon2::AccessControl;

=head1 DESCRIPTION

Amon2::AccessControl is ...

=head1 LICENSE

Copyright (C) mizuki_r.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

mizuki_r E<lt>ry.mizuki@gmail.comE<gt>

=cut

