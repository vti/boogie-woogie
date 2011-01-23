package BoogieWoogie::Renderer;

use Boose;
use Boose::Loader;
use Boose::Exception;

use Scalar::Util 'blessed';
use BoogieWoogie::Util 'camelize';

has app => {weak_ref => 1};
has 'default_handler';

sub render {
    my $self  = shift;
    my $input = shift;
    my %args  = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my @handlers_names = keys %{$self->{handlers}};
    throw('No renderer handlers were registered') unless @handlers_names;

    my $handler = $args{'-handler'};

    if (ref $input eq 'SCALAR') {
        $handler = $self->_get_handler($handler);
        return $handler->render_partial($$input, %args);
    }

    if (!$handler) {
        ($handler) = ($input =~ m/\.([^.]+)$/);
    }

    $handler = $self->_get_handler($handler);

    my $output;

    try {
        $output = $handler->render_file($input, %args);
    }
    catch {

        # Rethrow if it's not about template not being found
        throw($_) unless caught('BoogieWoogie::X::TemplateNotFound');
    };

    return unless defined $output;


    return $output;
}

sub register {
    my $self    = shift;
    my $handler = shift;

    my $engine = $_[0];

    if (!$engine || !blessed($engine)) {
        $engine = $self->_build_engine_from_handler($handler => @_);
    }

    $self->{handlers} ||= {};
    $self->{handlers}->{$handler} = $engine;

    $engine->set_app($self->app);
    $engine->build;

    return $self;
}

sub guess_handler {
    my $self = shift;

    my $handler = $self->default_handler;
    return $handler if $handler;

    my @handlers_names = keys %{$self->{handlers}};
    throw("Can't decide what handler to use from: " . join ' ' =>
        sort @handlers_names)
      if @handlers_names > 1;

    return $handlers_names[0];
}

sub _build_engine_from_handler {
    my $self    = shift;
    my $handler = shift;

    my $class = __PACKAGE__ . '::' . camelize($handler);

    Boose::Loader::load($class);

    return $class->new(@_);
}

sub _get_handler {
    my $self    = shift;
    my $handler = shift;

    $handler //= $self->guess_handler;

    throw("Unknown renderer handler '$handler'")
      unless exists $self->{handlers}->{$handler};

    #$self->log->debug(qq/Rendering with '$handler'/);

    return $self->{handlers}->{$handler};
}

1;
