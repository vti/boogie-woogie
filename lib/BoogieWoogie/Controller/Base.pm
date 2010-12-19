package BoogieWoogie::Controller::Base;
use Boose;

extends 'Boose::Base';

has [qw/app req res renderer/] => {weak_ref => 1};
has 'is_rendered';

sub param { shift->req->param(@_) }

sub render_text {
    my $self = shift;
    my $text = shift;

    $self->set_is_rendered(1);

    my $formats = $self->app->formats;

    $self->res->status(200);
    $self->res->content_type($formats->get_format('txt'));
    $self->res->body($text);

    return $self;
}

sub render {
    my $self   = shift;
    my $input  = shift;
    my %params = @_;

    my $output = $self->render_inline($input, %params);

    $self->set_is_rendered(1);

    if (defined $output) {
        my ($format, $handler);

        if (!ref $input) {
            (undef, $format, $handler) = $self->_parse_template_name($input);
        }

        $format //= $params{format} // 'html';

        my $formats = $self->app->formats;

        $self->res->status(200);
        $self->res->content_type($formats->get_format($format));
        $self->res->body($output);
    }
    else {
        $self->render_not_found;
    }

    return $self;
}

sub render_inline {
    my $self   = shift;
    my $input  = shift;
    my %params = @_;

    my $handler;
    my $format = $params{format} // 'html';

    if (ref $input eq 'SCALAR') {
        throw(  qq{Specify 'handler' parameter when }
              . qq{rendering from a string})
          unless exists $params{handler};

        $handler = $params{handler};
    }
    else {
        (undef, undef, $handler) = $self->_parse_template_name($input);
    }

    return $self->_render($handler, $input);
}

sub _parse_template_name {
    my $self     = shift;
    my $template = shift;

    return split /\./ => File::Basename::basename($template);
}

sub _render {
    my $self = shift;
    my ($handler, $input) = @_;

    my $vars = {};
    return $self->renderer->render($handler, $input, $vars);
}

sub render_not_found {
    my $self = shift;

    $self->set_is_rendered(1);

    my $formats = $self->app->formats;

    $self->res->status(404);
    $self->res->content_type($formats->get_format('html'));
    $self->res->body('404 Not Found');
}

sub add_action {
    my $class = shift;
    my ($name, $sub) = @_;

    $class::actions ||= {};
    $class::actions->{$name} = $sub;
}

sub action_exists {
    my $self = shift;
    my $name = shift;

    my $class = ref $self ? ref $self : $self;
    return exists $class::actions->{$name};
}

sub call_action {
    my $self = shift;
    my $name = shift;

    my $class = ref $self ? ref $self : $self;
    $class::actions->{$name}->($self);
}

1;
