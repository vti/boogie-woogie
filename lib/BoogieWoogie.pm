package BoogieWoogie;

use Boose;

use overload q(&{}) => sub { shift->psgi_app }, fallback => 1;

use BoogieWoogie::Formats;
use BoogieWoogie::Home;
use BoogieWoogie::Middleware::AutoRenderer;
use BoogieWoogie::Middleware::RoutesDispatcher;
use BoogieWoogie::Renderer;
use BoogieWoogie::Routes;
use BoogieWoogie::Util 'decamelize';

has 'formats'  => sub { BoogieWoogie::Formats->new };
has 'renderer' => sub { BoogieWoogie::Renderer->new };
has 'home'     => sub { BoogieWoogie::Home->new };
has 'routes'   => sub { BoogieWoogie::Routes->new };

sub new {
    my $self = shift->SUPER::new(@_);

    $self->home->detect_root_from_caller(caller);

    $self->renderer->set_app($self);

    $self->prepare_app;

    return $self;
}

sub url_for {
    my $self = shift;
    my $req  = shift;
    my $name = shift;
    my %args = @_;

    my $query  = delete $args{'?'};
    my $format = delete $args{format};

    my $path = $self->routes->build_path($name, %args);
    $path .= '.' . $format if defined $format;

    my $url = $req->base->clone;
    $url->path($url->path . $path);

    if ($query) {
        $url->query_form(
              ref $query eq 'ARRAY' ? @$query
            : ref $query eq 'HASH'  ? %$query
            : $query
        );
    }

    return $url;
}

sub app_name { decamelize ref shift }

sub prepare_app { }

sub psgi_app {
    my $self = shift;

    return $self->{psgi_app} ||= $self->_compile_psgi_app;
}

sub _compile_psgi_app {
    my $self = shift;

    my $app = sub {
        my $env = shift;

        $env->{'boogie_woogie.default'} = 1;

        return [404, [], ['404 Not Found']];
    };

    return $app;
}

1;
