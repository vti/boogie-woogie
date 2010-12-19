package BoogieWoogie::Renderer::TT;
use Boose;
extends 'BoogieWoogie::Renderer::Base';

use Template;

has 'tt';

sub build {
    my $self = shift;

    my $app    = $self->app;
    my $config = $self->config;

    my $default_config = {
        INCLUDE_PATH => $app->home->reldir('templates'),
        COMPILE_EXT  => '.ttc',
        COMPILE_DIR  => $app->tmpdir,
        UNICODE      => 1,
        ENCODING     => 'utf-8',
        CACHE_SIZE   => 128,
        RELATIVE     => 1,
        ABSOLUTE     => 1,
    };

    $config = {%$default_config, %$config};

    my $tt = Template->new($config);
    throw(qq{Can't create Template instance: $Template::ERROR}) unless $tt;

    $self->set_tt($tt);

    return $self;
}

sub _render_template {
    my $self     = shift;
    my $template = shift;
    my $output   = shift;

    my $tt = $self->tt;

    my $vars = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    my @params = ($vars, $output, {binmode => ':utf8'});
    my $ok = $tt->process($template, @params);

    return 1 if $ok;

    my $e = $tt->error;
    $$output = '';
    $tt->error('');

    return if $e =~ m/not found/;

    throw(qq/Template error in '$template': $e/);
}

1;
