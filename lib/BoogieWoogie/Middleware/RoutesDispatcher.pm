package BoogieWoogie::Middleware::RoutesDispatcher;

use Boose 'BoogieWoogie::Middleware';
use Boose::Loader;

use BoogieWoogie::Logger;
use BoogieWoogie::Request;
use BoogieWoogie::Util 'camelize';

has namespace => sub { ref shift->application };

sub routes    { shift->application->routes }

sub call {
    my ($self, $env) = @_;

    $self->log->set_env($env);

    my $res = $self->_dispatch($env);
    return $res if $res;

    return $self->app->($env);
}

sub _dispatch {
    my $self = shift;
    my $env  = shift;

    my $req = BoogieWoogie::Request->new($env);

    my $path = $req->path_info;

    my $match = $self->routes->match($path);

    unless ($match) {
        $self->log->debug(qq/Path '$path' does not match any route/);
        return;
    }

    my $params = $match->params;

    my $name = $params->{controller};

    throw("Controller was not specified") unless defined $name;

    my $controller = $self->_create_controller(
        $name,
        match => $match,
        req   => $req,
        res   => $req->new_response,
        app   => $self->application
    );
    return unless defined $controller;

    return $self->_run_controller($controller);
}

sub _create_controller {
    my $self = shift;
    my $name = shift;
    my @args = @_;

    my $controller_class = $self->_name_to_class($name);

    my $instance;

    try {
        Boose::Loader::load($controller_class);

        $instance = $controller_class->new(name => $name, @args);
    }
    catch {

        # Rethrow exception if it's not about class not being found
        throw($_) unless caught('Boose::Exception::ClassNotFound');

        $self->log->warn("Controller '$controller_class' not found");
    };

    return $instance;
}

sub _run_controller {
    my $self       = shift;
    my $controller = shift;

    my $retval = $controller->run;

    if (ref $retval eq 'CODE') {
        return $retval;
    }

    if ($controller->res->status) {
        return $controller->res->finalize;
    }

    # For other middlewares
    my $env = $controller->req->env;
    $env->{'boogie_woogie.controller'} = $controller->name;

    my $params = $controller->match;
    $env->{'boogie_woogie.format'}  = $params->{format};
    $env->{'boogie_woogie.handler'} = $params->{handler};

    return;
}

sub _name_to_class {
    my $self = shift;
    my $name = shift;

    $name = camelize($name) . 'Controller';

    my $namespace = $self->namespace;
    $name = $namespace . '::' . $name if $namespace;

    return $name;
}

1;
