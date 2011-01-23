package BoogieWoogie::X::TemplateError;

use Boose '::Exception';

has 'template';
has 'error';

sub message {
    my $self = shift;

    return sprintf "Template error in '%s'", $self->template;
}

1;
