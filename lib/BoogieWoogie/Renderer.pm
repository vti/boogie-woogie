package BoogieWoogie::Renderer;
use Boose;
extends 'Boose::Base';

has 'app';

sub render {
    my $self    = shift;
    my $handler = shift;
    my $input   = shift;

    my $output = '';
    my $ok = $self->_get_handler($handler)->render($input, \$output, @_);
    return unless $ok;

    return $output;
}

sub register {
    my $self = shift;
    my ($handler, $engine) = @_;

    $self->{handlers} ||= {};
    $self->{handlers}->{$handler} = $engine;

    $engine->set_app($self->app);
    $engine->build;

    return $self;
}

sub _get_handler {
    my $self    = shift;
    my $handler = shift;

    throw("Unknown renderer handler '$handler'")
      unless exists $self->{handlers}->{$handler};

    return $self->{handlers}->{$handler};
}

1;
