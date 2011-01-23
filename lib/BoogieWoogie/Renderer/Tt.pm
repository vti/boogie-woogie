package BoogieWoogie::Renderer::Tt;

use Boose 'BoogieWoogie::Renderer::Base';

use BoogieWoogie::X::TemplateNotFound;
use BoogieWoogie::X::TemplateError;

use Template;

has 'tt';

sub build {
    my $self = shift;

    my $app    = $self->app;
    my $config = $self->config;

    my $default_config = {
        INCLUDE_PATH => $app->home->reldir('templates'),
        COMPILE_EXT  => '.ttc',
        COMPILE_DIR  => $app->home->tmpdir,
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

sub render_file { shift->_render(@_) }

sub render_partial {
    my $self     = shift;
    my $template = shift;

    return $self->_render(\$template, @_);
}

sub _render {
    my $self     = shift;
    my $template = shift;

    my $tt = $self->tt;

    my $vars = ref $_[0] eq 'HASH' ? $_[0] : {@_};

    my $output = '';

    my $ok = $tt->process($template, $vars, \$output, {binmode => ':utf8'});
    return $output if $ok;

    my $e = $tt->error;
    $output = '';
    $tt->error('');

    if ($e =~ m/not found/) {
        BoogieWoogie::X::TemplateNotFound->throw(
            template => $template);
    }

    BoogieWoogie::X::TemplateError->throw(
        template => $template,
        error    => $e
    );
}

1;
