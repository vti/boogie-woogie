package BoogieWoogie::Formats;
use Boose;

has 'formats' => sub {
    {   txt  => 'text/plain',
        html => 'text/html'
    };
};

sub register {
    my $self = shift;
    my ($ext, $content_type) = @_;

    throw(qq/Args 'extension', 'content_type' are required/)
      unless defined $ext && $content_type;

    $self->formats->{$ext} = $content_type;

    return $self;
}

sub get_format {
    my $self = shift;
    my $ext  = shift;

    throw(qq/Extension '$ext' is not registered/)
      unless exists $self->formats->{$ext};

    return $self->formats->{$ext};
}

1;
