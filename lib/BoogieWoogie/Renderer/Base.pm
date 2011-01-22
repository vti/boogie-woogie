package BoogieWoogie::Renderer::Base;
use Boose;
extends 'Boose::Base';

has 'app' => {weak_ref => 1};
has 'encoding' => 'utf8';
has 'config' => sub { {} };

sub build { throw('Overwrite me') }

sub render_file {
    my $self     = shift;
    my $template = shift;

    my $input = $self->_slurp_file($template);

    return $self->render_partial($input, @_);
}

sub render_partial { throw('Overwrite me') }

sub _slurp_file {
    my $self = shift;
    my $path = shift;

    return unless -f $path;

    my $input = do { local $/; open my $file, '<', $path or return; <$file> };

    return $input;
}

1;
