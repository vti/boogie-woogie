package ControllerTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use TestController;
use TestChildController;

sub _build_object { shift; TestController->new(@_) }
sub _build_child_object { shift; TestChildController->new(@_) }

sub constructor : Test(1) {
    my $self = shift;

    my $c = $self->_build_object;
    ok $c;
}

sub action_exists : Test(2) {
    my $self = shift;

    my $c = $self->_build_object;

    ok $c->action_exists('foo');
    ok !$c->action_exists('bar');
}

sub call_action : Test(2) {
    my $self = shift;

    my $c = $self->_build_object;

    is $c->call_action('foo') => 'Hello world!';
    ok !$c->call_action('bar');
}

sub inheritance : Test(2) {
    my $self = shift;

    my $c = $self->_build_child_object;

    ok $c->action_exists('foo');
    ok $c->action_exists('bar');
}

1;
