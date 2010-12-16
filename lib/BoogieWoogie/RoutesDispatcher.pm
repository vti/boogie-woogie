package BoogieWoogie::RoutesDispatcher;
use Boose;

extends 'Boose::Base';

use Boose::Loader;
use Router;
use BoogieWoogie::Util qw(camelize);

has 'app';
has 'log';
has 'renderer';
has 'router' => sub { Router->new };

sub dispatch {
    my $self = shift;
    my $req  = shift;

    my $path = $req->path_info;

    if (my $match = $self->router->match($path)) {
        my $params = $match->params;

        my $controller = $params->{controller};
        my $action     = $params->{action};

        die "Don't know how to handle *this* yet, just die"
          unless defined $controller && defined $action;

        return unless $self->_is_action_valid($action);

        $controller = $self->_create_controller($controller);

        return unless defined $controller;

        if (!$controller->can($action)) {
            $self->log->warn(
                    "No action '$action' found within a controller '"
                  . ref($controller)
                  . "'");
            return;
        }

        $controller->bar;

        my $output =
            $controller->is_rendered
          ? $controller->output
          : $self->renderer->render;

        return $output;
    }

    return;
}

sub _is_action_valid {
    my $self   = shift;
    my $action = shift;

    if ($action !~ m/\A [a-z][\w_]+/xms) {
        $self->log->warn("Action '$action' is not valid");
    }

    return 1;
}

sub _create_controller {
    my $self = shift;
    my $name = shift;

    my $namespace = ref $self->app;
    $name = camelize($name);
    $name = $namespace . '::' . $name . 'Controller';

    my $controller;

    try {
        Boose::Loader::load($name);

        $controller = $name->new;
    }
    catch {

        # Rethrow exception if it's not about class not being found
        if (!Boose::Exception->caught(
                $_ => 'Boose::Exception::ClassNotFound'
            )
          )
        {
            throw($_);
        }

        $self->log->warn("Controller '$name' not found");
    };

    return $controller;
}

1;
