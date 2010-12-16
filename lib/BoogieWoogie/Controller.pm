package BoogieWoogie::Controller;
use Boose;

extends 'Boose::Base';

has 'app';
has 'is_rendered';
has 'output';

sub render {
    my $self = shift;

    $self->set_is_rendered(1);

    my $output = $self->renderer->render(@_);

    $self->set_output($output);
}

1;
