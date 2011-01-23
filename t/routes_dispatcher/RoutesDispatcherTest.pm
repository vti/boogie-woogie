package RoutesDispatcherTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;

use Plack::Test;
use HTTP::Request::Common;

use BoogieWoogie;
use BoogieWoogie::Routes;
use BoogieWoogie::Middleware::RoutesDispatcher;

sub _build_app {
    shift;
    my %args = @_;

    my $app = BoogieWoogie->new;

    my $routes = BoogieWoogie::Routes->new;

    if ($args{routes}) {
        $routes->add_route(@{$args{routes}});
    }

    $app->set_routes($routes);

    return BoogieWoogie::Middleware::RoutesDispatcher->wrap(
        $app->psgi_app,
        application => $app,
        namespace   => ''
    );
}

sub dispatch_with_no_routes : Test(1) {
    my $self = shift;

    my $app = $self->_build_app;

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        like $res->content, qr/404 Not Found/;
    };
}

sub dispatch_with_controller_not_found : Test(1) {
    my $self = shift;

    my $app =
      $self->_build_app(routes => ['/', defaults => 'unlikelytoexist']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        like $res->content, qr/404 Not Found/;
    };
}

sub dispatch_with_cant_load_controller : Test(2) {
    my $self = shift;

    my $app = $self->_build_app(routes => ['/', defaults => 'cant_load']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        ok $res->is_error;
        like $res->content, qr/syntax error/;
    };
}

sub dispatch_with_no_new_method : Test(2) {
    my $self = shift;

    my $app = $self->_build_app(routes => ['/', defaults => 'no_new']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        ok $res->is_error;
        like $res->content, qr/Can't locate object method "new"/;
    };
}

sub dispatch_with_die_during_new : Test(2) {
    my $self = shift;

    my $app =
      $self->_build_app(routes => ['/', defaults => 'die_during_new']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        ok $res->is_error;
        like $res->content, qr/Died inside new/;
    };
}

sub dispatch_with_empty_path : Test(1) {
    my $self = shift;

    my $app = $self->_build_app(routes => ['/', defaults => 'normal']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "");

        like $res->content, qr/NormalController/;
    };
}

sub dispatch_with_manual_response_settings : Test(1) {
    my $self = shift;

    my $app = $self->_build_app(routes => ['/', defaults => 'normal']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        like $res->content, qr/NormalController/;
    };
}

sub dispatch_without_controller : Test(2) {
    my $self = shift;

    my $app = $self->_build_app(routes => ['/']);

    test_psgi $app, sub {
        my $cb = shift;

        my $res = $cb->(GET "/");

        ok $res->is_error;
        like $res->content, qr/Controller was not specified/;
    };
}

1;
