package TtRendererTest;

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

    $r->register('tt');

    is $r->render(\'foobar [% 2 + 2 %]') => 'foobar 4';
}

sub file : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('tt', config => {INCLUDE_PATH => 't/renderer/templates'});

    is $r->render('foo.tt') => "2\n";
}

sub syntax_error : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('tt', config => {INCLUDE_PATH => 't/renderer/templates'});

    my $e;
    try {
        $r->render('error.tt');
    }
    catch {
        $e = $_;
    };

    like $e => qr/Template error in 'error.tt'/;
}

sub file_not_found : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register('tt');

    ok not defined $r->render('bar.tt');
}

1;
