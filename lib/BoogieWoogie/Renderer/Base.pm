package BoogieWoogie::Renderer::Base;
use Boose;
extends 'Boose::Base';

has 'app';
has 'encoding' => 'utf8';
has 'config' => sub { {} };

sub build { throw('Overwrite me') }

sub render {
    my $self   = shift;
    my $input  = shift;
    my $output = shift;

    if (ref $input eq 'SCALAR') {
        return $self->_render_string($$input, $output, @_);
    }

    return $self->_render_template($input, $output, @_);
}

sub _render_template {
    my $self     = shift;
    my $template = shift;
    my $output   = shift;

    my $input = $self->_slurp_file($template);
    return unless defined $input;

    return $self->_render_string($input, $output, @_);
}

sub _render_string { throw('Overwrite me') }

sub _slurp_file {
    my $self = shift;
    my $path = shift;

    return unless -f $path;

    my $input = do { local $/; open my $file, '<', $path or return; <$file> };

    return $input;
}

1;
