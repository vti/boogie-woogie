package BoogieWoogie::Controller;

use strict;
use warnings;

use base 'Boose';

use Boose::Util qw(install_sub);

sub import_finalize {
    my $class = shift;
    my ($package) = @_;

    $class->SUPER::import_finalize(@_);

    install_sub($package => action => \&action);
}

sub action { caller->add_action(@_) }

1;
