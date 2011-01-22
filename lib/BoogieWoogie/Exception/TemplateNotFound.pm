package BoogieWoogie::Exception::TemplateNotFound;

use Boose '::Exception';

has 'template';

sub message {
    my $self = shift;

    return sprintf "Template '%s' not found", $self->template;
}

1;
