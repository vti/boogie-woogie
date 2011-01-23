package BoogieWoogie::Middleware;

use Boose 'Plack::Middleware';
use BoogieWoogie::Logger;

has 'application' => {weak_ref => 1};

has 'log' => sub { BoogieWoogie::Logger->new };

sub prepare_app {
    my $self = shift;

    throw('Application is required') unless $self->application;
}

1;
