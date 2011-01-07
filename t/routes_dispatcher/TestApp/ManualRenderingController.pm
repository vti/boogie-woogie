package TestApp::ManualRenderingController;
use BoogieWoogie::Controller;

sub run {
    my $self = shift;

    $self->res->status(200);
    $self->res->body('hello');
}

1;
