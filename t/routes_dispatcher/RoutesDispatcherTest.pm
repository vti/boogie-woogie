package RoutesDispatcherTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use BoogieWoogie::Request;
use BoogieWoogie::RoutesDispatcher;

use TestApp;

sub _build_object {
    shift;
    BoogieWoogie::RoutesDispatcher->new(app => TestApp->new, @_);
}
sub _build_req { shift; BoogieWoogie::Request->new(@_) }

sub constructor : Test(1) {
    my $self = shift;

    my $d = $self->_build_object;
    ok $d;
}

sub dispatch_with_no_routes : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    my $res = $d->dispatch($req);
    ok $res->isa('BoogieWoogie::Response');
    is $res->status => 404;
}

sub dispatch_with_controller_not_found : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    $d->router->add_route('/', defaults => 'unlikelytoexist');
    my $res = $d->dispatch($req);
    ok $res->isa('BoogieWoogie::Response');
    is $res->status => 404;
}

sub dispatch_with_cant_load_controller : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    $d->router->add_route('/', defaults => 'cant_load');

    try {
        $d->dispatch($req);
    }
    catch {
        ok $_;
        like $_ => qr/syntax error/;
    };
}

sub dispatch_with_no_new_method : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    $d->router->add_route('/', defaults => 'no_new');

    try {
        $d->dispatch($req);
    }
    catch {
        ok $_;
        like $_ => qr/Can't locate object method "new"/;
    };
}

sub dispatch_with_die_during_new : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    $d->router->add_route('/', defaults => 'die_during_new');

    try {
        $d->dispatch($req);
    }
    catch {
        ok $_;
        like $_ => qr/Died inside new/;
    };
}

sub dispatch_with_self_rendering : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    $d->router->add_route('/', defaults => 'foo');
    my $res = $d->dispatch($req);
    ok $res->isa('BoogieWoogie::Response');
    is $res->status => 200;
}

sub dispatch_with_empty_path : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => ''});

    $d->router->add_route('/', defaults => 'foo');
    my $res = $d->dispatch($req);
    ok $res->isa('BoogieWoogie::Response');
    is $res->status => 200;
}

sub dispatch_without_controller : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});
    $d->router->add_route('/');

    my $e;
    try {
        $d->dispatch($req);
    }
    catch {
        $e = $_;
    };

    ok $e;
}

sub dispatch_with_manual_response_settings : Test(2) {
    my $self = shift;

    my $d = $self->_build_object;
    my $req = $self->_build_req({PATH_INFO => '/'});

    $d->router->add_route('/', defaults => 'manual_rendering');
    my $res = $d->dispatch($req);
    is $res->status => 200;
    is $res->body   => 'hello';
}

sub url_for : Test(7) {
    my $self = shift;

    my $d   = $self->_build_object;
    my $req = $self->_build_req(
        {PATH_INFO => '/', SERVER_NAME => 'localhost', SERVER_PORT => 80});

    $d->router->add_route('/',            name => 'root');
    $d->router->add_route('/articles',    name => 'articles');
    $d->router->add_route('/article/:id', name => 'article');

    is $d->url_for($req, 'root') => 'http://localhost/';
    is $d->url_for($req, 'root', format => 'html') =>
      'http://localhost/.html';

    is $d->url_for($req, 'articles') => 'http://localhost/articles';
    is $d->url_for($req, 'articles', format => 'html') =>
      'http://localhost/articles.html';

    is $d->url_for($req, 'article', id => 123) =>
      'http://localhost/article/123';
    is $d->url_for($req, 'article', id => 123, '?' => [1 => 2]) =>
      'http://localhost/article/123?1=2';
}

1;
