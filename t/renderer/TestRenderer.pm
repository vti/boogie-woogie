package TestRenderer;

use Boose 'BoogieWoogie::Renderer::Base';

sub build {
}

sub render_partial {
    my $self  = shift;
    my $input = shift;

    return $input;
}

1;
