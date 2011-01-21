package TestApp::FooController;
use Boose 'BoogieWoogie::Controller';

sub run {
    my $self = shift;

    $self->render_text('hello');
};

1;
