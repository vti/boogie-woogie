package BoogieWoogie::View;
use Boose 'Text::Caml';

use BoogieWoogie::Util 'decamelize';

has [qw/app req/] => {is_weak => 1};
has 'format' => 'html';
has 'templates_path' => sub { $_[0]->app->home->reldir('views') };

sub url_for {
    my $self = shift;

    return $self->app->dispatcher->url_for($self->req, @_);
}

sub _class_to_template {
    my $self = shift;

    my $prefix = decamelize(ref $self->app);

    my $template = $self->SUPER::_class_to_template;

    $template =~ s/^$prefix-//i;

    return $template;
}

1;
