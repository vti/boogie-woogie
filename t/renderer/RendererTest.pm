package RendererTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use TestApp;
use TestRenderer;
use BoogieWoogie::Renderer;

sub _build_object {
    shift;
    BoogieWoogie::Renderer->new(app => TestApp->new, @_);
}

sub constructor : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;
    ok $r;
}

sub no_handlers_partial : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    my $e;
    try {
        $r->render(\'foobar', -handler => 'tt');
    }
    catch {
        $e = $_;
    };

    like $e => qr/No renderer handlers were registered/;
}

sub unknown_handler_partial : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(txt => TestRenderer->new);

    my $e;
    try {
        $r->render(\'foobar', -handler => 'tt');
    }
    catch {
        $e = $_;
    };

    like $e => qr/Unknown renderer handler 'tt'/;
}

sub what_handler_partial : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(foo => TestRenderer->new);
    $r->register(bar => TestRenderer->new);

    my $e;
    try {
        $r->render(\'foobar');
    }
    catch {
        $e = $_;
    };

    like $e => qr/Can't decide what handler to use from: bar foo/;
}

sub default_handler_partial : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(txt => TestRenderer->new);

    is $r->render(\'foobar') => 'foobar';
}

sub partial : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(tt => TestRenderer->new);
    my $output = $r->render(\'foobar', -handler => 'tt');

    is $output => 'foobar';
}

sub render_template : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(txt => TestRenderer->new);
    my $output = $r->render('t/renderer/templates/foo.txt');

    is $output => "Hello!\n";
}

sub render_template_not_found : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(foo => TestRenderer->new);
    ok not defined $r->render('bar.foo');
}

1;
