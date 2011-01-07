package ConfigLoaderTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use BoogieWoogie::ConfigLoader;

sub _build_object { shift; BoogieWoogie::ConfigLoader->new(@_) }

sub constructor : Test(1) {
    my $self = shift;

    my $config_loader = $self->_build_object;
    ok $config_loader;
}

sub not_found : Test(1) {
    my $self = shift;

    my $config_loader = $self->_build_object;

    $config_loader->set_home('/');
    $config_loader->set_file('my_app');
    is_deeply $config_loader->load => {};
}

sub perl : Test(1) {
    my $self = shift;

    my $config_loader = $self->_build_object;

    $config_loader->set_home("t/config_loader/configs/");
    is_deeply $config_loader->load => {foo => 'bar'};
}

1;
