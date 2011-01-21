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

    my $name = $params->{controller};

    die "Don't know how to handle *this* yet, just die"
      unless defined $name;

    my $controller = $self->_create_controller($name);
    return $self->_build_not_found_response($res) unless defined $controller;

    $controller->set_match($match);
    $controller->set_app($self->app);
    $controller->set_req($req);
    $controller->set_res($res);

    $controller->set_name($name);

    my $retval = $controller->run;
    return $res if $controller->is_rendered;

    return $retval if ref $retval eq 'CODE';

    return $res if $res->status;

    $controller->render;

    return $res;
}

sub url_for {
    my $self = shift;
    my $req  = shift;
    my $name = shift;
    my %args = @_;

    my $query  = delete $args{'?'};
    my $format = delete $args{format};

    my $path = $self->router->build_path($name, %args);
    $path .= '.' . $format if defined $format;

    my $url = $req->base->clone;
    $url->path($url->path . $path);

    if ($query) {
        $url->query_form(
              ref $query eq 'ARRAY' ? @$query
            : ref $query eq 'HASH'  ? %$query
            :                         $query);
    }

    return $url;
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
