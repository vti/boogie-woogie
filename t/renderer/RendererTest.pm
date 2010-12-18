package RendererTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use TestRenderer;
use BoogieWoogie::Renderer;

sub _build_object { shift; BoogieWoogie::Renderer->new(@_) }

sub constructor : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;
    ok $r;
}

sub unknown_handler : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    my $e;
    try {
        $r->render(tt => \'foobar');
    }
    catch {
        $e = $_;
    };

    like $e => qr/Unknown renderer handler 'tt'/;
}

sub render_string : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(tt => TestRenderer->new);
    my $output = $r->render(tt => \'foobar');

    is $output => 'foobar';
}

sub render_template : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(txt => TestRenderer->new);
    my $output = $r->render(txt => 't/renderer/templates/foo.txt');

    is $output => "Hello!\n";
}

sub render_template_not_found : Test(1) {
    my $self = shift;

    my $r = $self->_build_object;

    $r->register(foo => TestRenderer->new);
    ok not defined $r->render(foo => 'bar.foo');
}
1;
