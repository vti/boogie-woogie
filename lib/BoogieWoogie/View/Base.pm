package BoogieWoogie::View::Base;
use Boose;
extends 'Text::Caml';

has 'app' => {is_weak => 1};
has 'format' => 'html';
has 'templates_path' => sub { $_[0]->app->home->reldir('views') };

sub _class_to_template {
    my $self = shift;

    my $prefix = ref $self->app;

    my $template = $self->SUPER::_class_to_template;

    $template =~ s/^$prefix-//i;

    return $template;
}

1;
