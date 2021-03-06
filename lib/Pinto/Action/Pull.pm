# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::Types::Moose qw(Undef Bool);

use Pinto::Types qw(Specs StackName);

use namespace::autoclean;

#------------------------------------------------------------------------------

# VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => Specs,
    traits   => [ qw(Array) ],
    handles  => {targets => 'elements'},
    required => 1,
    coerce   => 1,
);


has stack => (
    is        => 'ro',
    isa       => StackName | Undef,
    default   => undef,
    coerce    => 1,
);


has pin => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has norecurse => (
    is        => 'ro',
    isa       => Bool,
    default   => 0,
);


has dryrun => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repos->get_stack(name => $self->stack);

    $self->_execute($_, $stack) for $self->targets;

    $self->repos->write_index(stack => $stack) if $self->result->made_changes;

    return $self->result;
}

#------------------------------------------------------------------------------

sub _execute {
    my ($self, $target, $stack) = @_;

    my ($dist, $did_pull) = $self->repos->get_or_pull( target => $target,
                                                       stack  => $stack );

    $dist->pin( stack => $stack ) if $dist && $self->pin;

    if ($dist and not $self->norecurse) {
        my @prereq_dists = $self->repos->pull_prerequisites( dist  => $dist,
                                                             stack => $stack );
        $did_pull += @prereq_dists;
    }

    $self->result->changed if $did_pull and not $self->dryrun;

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__
