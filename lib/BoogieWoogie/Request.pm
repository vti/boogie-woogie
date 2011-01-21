package BoogieWoogie::Request;
use Boose 'Plack::Request';

use BoogieWoogie::Response;

sub new_response {
    my $self = shift;

    return BoogieWoogie::Response->new;
}

1;
