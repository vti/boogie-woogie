package BoogieWoogie;
use Boose;

extends 'Boose::Base';

use overload q(&{}) => sub { shift->psgi_app }, fallback => 1;

use Scalar::Util 'blessed';
use Plack::Request;
use Plack::Response;

use BoogieWoogie::Renderer;
use BoogieWoogie::RoutesDispatcher;
use BoogieWoogie::Logger;

has 'dispatcher' => sub { BoogieWoogie::RoutesDispatcher->new };
has 'renderer'   => sub { BoogieWoogie::Renderer->new };
has 'logger'     => sub { BoogieWoogie::Logger->new };

sub new {
    my $self = shift->SUPER::new(@_);

    $self->dispatcher->set_app($self);
    $self->dispatcher->set_log($self->logger);
    $self->dispatcher->set_renderer($self->renderer);

    $self->startup;

    return $self;
}

sub startup { }

sub psgi_app {
    my $self = shift;

    return $self->{psgi_app} ||= $self->_compile_psgi_app;
}

sub _compile_psgi_app {
    my $self = shift;

    my $app = sub {
        my $env = shift;

        my $req = Plack::Request->new($env);

        unless ($self->logger->logger) {
            $self->logger->set_logger($env->{'psgix.logger'});
        }

        my $output = $self->dispatcher->dispatch($req);

        if (not defined $output) {
            return [404, ['Content-Type' => 'text/html'], ["404 Not Found"]];
        }
        elsif (blessed($output) && $output->isa('Plack::Response')) {
            return $output->finalize;
        }
        elsif (ref $output eq 'CODE') {
            return $output;
        }
        else {
            my $res = Plack::Response->new(200);
            $res->content_type('text/html');
            $res->body($output);
            return $res->finalize;
        }
    };

    return $app;
}

1;
