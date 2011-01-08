package BoogieWoogie::View::Base;
use Boose;
extends 'Text::Caml';

has 'app' => {is_weak => 1};
has 'format' => 'html';
has 'templates_path' => sub { $_[0]->app->home->reldir('views') };

1;
