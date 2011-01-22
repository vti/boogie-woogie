package NormalController;

use Boose 'BoogieWoogie::Controller';

sub run {
    my $self = shift;

    my $res = $self->res;

    $res->status(200);
    $res->body('NormalController');
}

1;
