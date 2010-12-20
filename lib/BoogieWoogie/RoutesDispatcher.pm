package BoogieWoogie::RoutesDispatcher;
use Boose;
extends 'Boose::Base';

use Router;
use Boose::Loader;
use BoogieWoogie::Util qw(camelize);
use BoogieWoogie::NullLogger;

has [qw/app/] => {weak_ref => 1};
has 'controller_namespace' => sub { ref $_[0]->app };
has 'log'                  => sub { BoogieWoogie::NullLogger->new };
has 'router'               => sub { Router->new };

sub dispatch {
    my $self = shift;
    my $req  = shift;

    my $res = $req->new_response;

    my $path = $req->path_info;

    my $match = $self->router->match($path);

    unless ($match) {
        $self->log->debug(qq/Path '$path' does not match any route/);
        return $self->_build_not_found_response($res);
    }

    my $params = $match->params;

    my $controller_name = $params->{controller};
    my $action_name     = $params->{action};

    die "Don't know how to handle *this* yet, just die"
      unless defined $controller_name && defined $action_name;

    my $controller = $self->_create_controller($controller_name);
    return $self->_build_not_found_response($res) unless defined $controller;

    if (!$controller->action_exists($action_name)) {
        $self->log->warn("No action '$action_name' found within a controller '"
              . ref($controller)
              . "'");
        return $self->_build_not_found_response($res);
    }

    $controller->set_app($self->app);
    $controller->set_req($req);
    $controller->set_res($res);

    $controller->set_controller_name($controller_name);
    $controller->set_action_name($action_name);

    my $action_retval = $controller->call_action($action_name);
    return $res if $controller->is_rendered;

    return $action_retval if ref $action_retval eq 'CODE';

    return $res if $res->status;

    my $output = $controller->render;
    $res->status(200);
    $res->body($output);

    return $res;
}

sub _build_not_found_response {
    my $self = shift;
    my $res  = shift;

    $res->status(404);
    $res->content_type('text/html');
    $res->body('404 Not Found');
    return $res;
}

sub _create_controller {
    my $self = shift;
    my $name = shift;

    my $controller_class = $self->_name_to_class($name);

    my $instance;

    try {
        Boose::Loader::load($controller_class);

        $instance = $controller_class->new;
    }
    catch {
        my $class_not_found =
          Boose::Exception->caught($_ => 'Boose::Exception::ClassNotFound');

        # Rethrow exception if it's not about class not being found
        throw($_) unless $class_not_found;

        $self->log->warn("Controller '$controller_class' not found");
    };

    return $instance;
}

sub _name_to_class {
    my $self = shift;
    my $name = shift;

    $name = camelize($name) . 'Controller';

    my $namespace = $self->controller_namespace;
    $name = $namespace . '::' . $name if $namespace;

    return $name;
}

1;
