package BoogieWoogie::Middleware::RoutesDispatcher;

use Boose 'Plack::Middleware';
use Boose::Loader;
use Boose::Exception;

use BoogieWoogie::Logger;
use BoogieWoogie::Request;
use BoogieWoogie::Util 'camelize';

has 'namespace';
has 'controller_args' => sub { [] };
has 'routes';
has 'log' => sub { BoogieWoogie::Logger->new };

sub call {
    my ($self, $env) = @_;

    $self->log->set_env($env);

    my $res = $self->_dispatch($env);
    return $res if $res;

    $self->app->($env);
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
        @{$self->controller_args}
    );
    return unless defined $controller;

    $env->{'boogie_woogie.controller'} = $name;

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
        my $class_not_found =
          Boose::Exception->caught($_ => 'Boose::Exception::ClassNotFound');

        # Rethrow exception if it's not about class not being found
        throw($_) unless $class_not_found;

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
