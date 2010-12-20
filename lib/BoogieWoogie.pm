package BoogieWoogie;
use Boose;

extends 'Boose::Base';

use overload q(&{}) => sub { shift->psgi_app }, fallback => 1;

use Scalar::Util 'blessed';

use BoogieWoogie::Request;
use BoogieWoogie::Response;
use BoogieWoogie::Home;
use BoogieWoogie::RoutesDispatcher;
use BoogieWoogie::Logger;
use BoogieWoogie::Formats;

has 'home'       => sub { BoogieWoogie::Home->new };
has 'dispatcher' => sub { BoogieWoogie::RoutesDispatcher->new };
has 'log'        => sub { BoogieWoogie::Logger->new };
has 'formats'    => sub { BoogieWoogie::Formats->new };

has 'tmpdir' => sub { require File::Spec; File::Spec->tmpdir };

sub new {
    my $self = shift->SUPER::new(@_);

    $self->home->detect_root_from_caller(caller);

    $self->dispatcher->set_app($self);
    $self->dispatcher->set_log($self->log);

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

        my $req = BoogieWoogie::Request->new($env);

        $self->log->set_logger($env->{'psgix.logger'});

        my $output = $self->dispatcher->dispatch($req);

        if (not defined $output) {
            return [404, ['Content-Type' => 'text/html'], ["404 Not Found"]];
        }
        elsif (blessed($output) && $output->isa('BoogieWoogie::Response')) {
            return $output->finalize;
        }
        elsif (ref $output eq 'CODE') {
            return $output;
        }
        else {
            my $res = BoogieWoogie::Response->new(200);
            $res->content_type('text/html');
            $res->body($output);
            return $res->finalize;
        }
    };

    return $app;
}

1;
