package BoogieWoogie::Renderer::Caml;

use Boose 'BoogieWoogie::Renderer::Base';

use BoogieWoogie::X::TemplateNotFound;
use BoogieWoogie::X::TemplateError;

use Text::Caml;

has 'caml';

sub build {
    my $self = shift;

    my $app    = $self->app;
    my $config = $self->config;

    my $default_config = {templates_path => $app->home->reldir('templates')};

    $config = {%$default_config, %$config};

    my $caml = Text::Caml->new(%$config);

    $self->set_caml($caml);

    return $self;
}

sub render_file    { shift->_render('render_file' => @_) }
sub render_partial { shift->_render('render'      => @_) }

sub _render {
    my $self     = shift;
    my $method   = shift;
    my $template = shift;
    my @args     = @_;

    my $output;

    try {
        $output = $self->caml->$method($template, @args);
    }
    catch {
        if ($_ !~ m/Can't find/) {
            BoogieWoogie::X::TemplateError->throw(
                template => $template,
                error    => $_
            );
        }
    };

    unless (defined $output) {
        BoogieWoogie::X::TemplateNotFound->throw(
            template => $template);
    }

    return $output;
}

1;
