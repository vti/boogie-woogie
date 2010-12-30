package BoogieWoogie::Controller::Base;
use Boose;
extends 'Boose::Base';

use BoogieWoogie::Util 'camelize';
use Scalar::Util 'blessed';

has [qw/app req res/] => {weak_ref => 1};
has 'is_rendered';

has 'controller_name';
has 'action_name';

static 'actions' => sub { {} };

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

sub render_partial {
    my $self = shift;

    if (@_ % 2 == 0) {
        my $view = $self->_build_view(@_);

        return unless defined $view;

        return $view->render;
    }
    elsif (ref $_[0] eq 'SCALAR') {
        my $template = shift;

        my $view = $self->_build_view('BoogieWoogie::View');

        return unless defined $view;

        return $view->render($$template, {@_});
    }
    elsif (blessed($_[0])) {
        my $view = shift;

        $view = $self->_setup_view($view);

        return $view->render;
    }
    else {
        die 'TODO';
    }
}

sub render {
    my $self = shift;

    my $format = 'html';

    my $output = $self->render_partial(@_);

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

    $class->actions->{$name} = $sub;
}

sub action_exists {
    my $self = shift;
    my $name = shift;

    return unless exists $self->actions->{$name};
}

sub call_action {
    my $self = shift;
    my $name = shift;

    return unless $self->action_exists($name);

    return $self->actions->{$name}->($self);
}

sub _setup_view {
    my $self = shift;
    my $view = shift;

    $view->set_app($self->app);

    return $view;
}

sub _build_view {
    my $self = shift;

    my $class;
    if (@_ % 2 == 0) {
        my $controller = $self->controller_name;
        my $action     = $self->action_name;

        $class =
          ref($self->app) . '::' . camelize("$controller\_$action\_view");
    }
    else {
        $class = shift;
    }

    return unless defined $self->_load_view($class);

    my $view = $class->new(@_);

    return $self->_setup_view($view);
}

sub _load_view {
    my $self  = shift;
    my $class = shift;

    try {
        Boose::Loader::load($class);
        return $class;
    }
    catch {
        my $class_not_found =
          Boose::Exception->caught($_ => 'Boose::Exception::ClassNotFound');

        # Rethrow exception if it's not about class not being found
        throw($_) unless $class_not_found;

        $self->app->log->warn("View '$class' not found");

        return;
    };
}

1;
