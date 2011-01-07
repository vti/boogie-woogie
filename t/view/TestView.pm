package TestView;
use BoogieWoogie::View;

has 'body';
has 'title';
has 'format' => 'html';

sub to_hash {
    my $self = shift;

    return {title => $self->title, body => $self->body};
}

1;
