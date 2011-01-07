package TestApp::FooController;
use BoogieWoogie::Controller;

sub run {
    my $self = shift;

    $self->render_text('hello');
};

1;
