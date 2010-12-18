package TestRenderer;
use Boose;
extends 'BoogieWoogie::Renderer::Base';

sub build {
}

sub _render_string {
    my $self   = shift;
    my $input  = shift;
    my $output = shift;

    $$output = $input;
    return 1;
}

1;
