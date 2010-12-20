package BoogieWoogie::Controller::Base;
use Boose;

extends 'Boose::Base';

use BoogieWoogie::Util 'camelize';

has [qw/app req res/] => {weak_ref => 1};
has 'is_rendered';

has 'controller_name';
has 'action_name';

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
    my $self = shift;

    my $format = 'html';

    my $view = $self->_build_view(@_, format => $format);

    my $output = $view->render;

    $self->set_is_rendered(1);

    if (defined $output) {
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

sub _build_view {
    my $self = shift;

    my $view;

    if (@_ % 2 == 0) {
        my $controller = $self->controller_name;
        my $action = $self->action_name;

        $view = ref($self->app) . '::' . camelize("$controller\_$action\_view");

        Boose::Loader::load($view);
        $view = $view->new(@_);
    }
    else {
        die 'TODO';
    }

    $view->set_app($self->app);

    return $view;
}

sub render_partial {
    die 'TODO';
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
