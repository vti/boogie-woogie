package CamlRendererTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use TestApp;
use BoogieWoogie::Renderer;

sub _build_object {
    shift;
    BoogieWoogie::Renderer->new(app => TestApp->new, @_);
}

sub partial : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('caml');

    is $r->render(\'Hello, {{name}}!', {name => 'foo'}) => 'Hello, foo!';
}

sub file : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('caml', config => {templates_path => 't/renderer/templates'});

    is $r->render('foo.caml', {name => 'bar'}) => "Hello, bar!";
}

sub syntax_error : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('caml', config => {templates_path => 't/renderer/templates'});

    my $e;
    try {
        $r->render('error.caml');
    }
    catch {
        $e = $_;
    };

    like $e => qr/Template error/;
}

sub file_not_found : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('caml');

    ok not defined $r->render('bar.caml');
}

1;
