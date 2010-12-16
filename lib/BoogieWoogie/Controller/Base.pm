package BoogieWoogie::Controller::Base;
use Boose;

extends 'Boose::Base';

has 'app';
has 'is_rendered';
has 'output';

sub render_text {
    my $self = shift;
    my $text = shift;

    $self->set_is_rendered(1);

    $self->set_output($text);
}

sub render {
    my $self = shift;

    $self->set_is_rendered(1);

    my $output = $self->renderer->render(@_);

    $self->set_output($output);
}

sub add_action {
    my $class = shift;
    my ($name, $sub) = @_;

    $class::actions ||= {};
    $class::actions->{$name} = $sub;
}

sub action_exists {
    my $self = shift;
    my $name = shift;

    my $class = ref $self ? ref $self : $self;
    return exists $class::actions->{$name};
}

sub call_action {
    my $self = shift;
    my $name = shift;

    my $class = ref $self ? ref $self : $self;
    $class::actions->{$name}->($self);
}

1;
