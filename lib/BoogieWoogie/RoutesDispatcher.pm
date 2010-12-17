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

        $controller = $self->_create_controller($controller);
        return unless defined $controller;

        if (!$controller->action_exists($action)) {
            $self->log->warn(
                    "No action '$action' found within a controller '"
                  . ref($controller)
                  . "'");
            return;
        }

        my $res = $req->new_response;

        $controller->set_req($req);
        $controller->set_res($res);

        $controller->call_action($action);

        if (!$controller->is_rendered) {
            my $output = $self->renderer->render;
            $res->status(200);
            $res->body($output);
        }

        return $res;
    }

    return;
}

sub _create_controller {
    my $self = shift;
    my $name = shift;
    my ($req, $res) = @_;

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
        my $e =
          Boose::Exception->caught($_ => 'Boose::Exception::ClassNotFound');

        if (!$e) {
            throw($_);
        }

        $self->log->warn("Controller '$name' not found");
    };

    return $controller;
}

1;
