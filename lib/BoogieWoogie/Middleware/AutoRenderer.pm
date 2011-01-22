package BoogieWoogie::Middleware::AutoRenderer;

use Boose 'Plack::Middleware'

has 'renderer';

sub call {
    my ($self, $env) = @_;

    my $res = $self->app->($env);
    return $res if ref $res eq 'CODE';
    return $res if $res->status;

    my $controller = $env->{'boogie_woogie.controller'};
    my $format     = $env->{'boogie_woogie.format'};

    my $formats = $self->app->formats;

    $self->res->status(200);
    $self->res->content_type($formats->get_format($format));
    $self->res->body($output);
}

1;
