package BoogieWoogie::Controller;

use Boose;

use BoogieWoogie::Logger;
use BoogieWoogie::Util qw/camelize slurp/;

has 'vars' => sub { {} };
has [qw/app req res/] => {weak_ref => 1};
has 'match';
has 'name';
has log => sub { BoogieWoogie::Logger->new(env => shift->req->env) };

sub keep {
    my $self = shift;
    my %vars = @_;

    while (my ($key, $value) = each %vars) {
        $self->vars->{$key} = $value;
    }

    return $self;
}

sub param { shift->req->param(@_) }

sub render_text {
    my $self = shift;
    my $text = shift;

    my $formats = $self->app->formats;

    $self->res->status(200);
    $self->res->content_type($formats->get_format('txt'));
    $self->res->body($text);

    return $self;
}

sub render_partial {
    my $self = shift;

    return $self->app->renderer->render(@_, vars => $self->vars);
}

sub render {
    my $self = shift;

    my $format = 'html';

    my $output = $self->render_partial(@_);

    if (defined $output) {
        my $formats = $self->app->formats;

        $self->res->status(200);
        $self->res->content_type($formats->get_format($format));
        $self->res->body($output);
    }
    else {
        $self->log->debug('Rendering failed');
        $self->render_not_found;
    }

    return $self;
}

sub render_not_found {
    my $self = shift;

    my $formats = $self->app->formats;

    $self->res->status(404);
    $self->res->content_type($formats->get_format('html'));
    $self->res->body('404 Not Found');
}

sub redirect {
    my $self = shift;

    my $url_for = $self->url_for(@_);

    $self->res->status(302);
    $self->res->location($url_for);
    $self->res->body('302 Redirect');
}

sub url_for {
    my $self = shift;

    return $self->app->url_for($self->req, @_);
}

1;
