package BoogieWoogie::Renderer::Tenjin;
use Boose;
extends 'BoogieWoogie::Renderer::Base';

use Tenjin;

has 'tenjin';

sub build {
    my $self = shift;

    my $app    = $self->app;
    my $config = $self->config;

    my $default_config = {
        strict   => 1,
        path     => [$app->home->reldir('templates')],
        cache    => 1,
        encoding => 'utf8'
    };

    $config = {%$default_config, %$config};

    my $tenjin = Tenjin->new($config);

    $self->set_tenjin($tenjin);

    return $self;
}

sub _render_template {
    my $self     = shift;
    my $template = shift;
    my $output   = shift;

    my $tenjin = $self->tenjin;

    my $vars = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    my $not_found;
    try {
        $$output = $tenjin->render($template, $vars);
    }
    catch {
        $$output = '';

        if ($_ =~ m/ not found in path/) {
            $not_found = 1;
        }
        else {
            throw($_);
        }
    };

    return if $not_found;

    return 1;
}

sub render_string {
}

1;
