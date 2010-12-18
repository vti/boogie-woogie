package TestApp::FooController;
use BoogieWoogie::Controller;
extends 'BoogieWoogie::Controller::Base';

action bar => sub {
    my $self = shift;

    $self->render_text('hello');
};

action manual => sub {
    my $self = shift;

    $self->res->status(200);
    $self->res->body('hello');
};

1;
