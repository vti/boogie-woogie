package BoogieWoogie::Home;
use Boose;
extends 'Boose::Base';

require File::Spec;
require File::Basename;

has 'root';

sub detect_root_from_caller {
    my $self = shift;
    my ($package, $script) = @_;

    $self->set_root(File::Basename::dirname(File::Spec->rel2abs($script)));
}

sub reldir {
    my $self = shift;

    return File::Spec->catdir($self->root, @_);
}

1;
