package BoogieWoogie::Middleware::AutoRenderer;

use Boose 'BoogieWoogie::Middleware';

use BoogieWoogie::Request;

sub renderer { shift->application->renderer }

sub call {
    my ($self, $env) = @_;

    $self->log->set_env($env);

    my $res = $self->app->($env);

    return $self->response_cb(
        $res => sub {
            my $res = shift;

            if (defined $res && !delete $env->{'boogie_woogie.default'}) {
                return $res if ref $res eq 'CODE';
                return $res if ref $res eq 'ARRAY';
                return $res if $res->status;
            }

            @$res = @{$self->_render($env)};
        }
    );
}

sub _render {
    my $self = shift;
    my $env  = shift;

    my $req = BoogieWoogie::Request->new($env);
    my $res = $req->new_response;

    my $controller = $env->{'boogie_woogie.controller'};
    my $format     = $env->{'boogie_woogie.format'} || 'html';
    my $handler    = $env->{'boogie_woogie.handler'}
      || $self->renderer->guess_handler;

    #my $formats = $self->app->formats;

    my $template = "$controller.$format.$handler";

    $self->log->debug("Autorendering $template");

    if (defined(my $output = $self->renderer->render($template))) {
        $res->status(200);
        $res->body($output);
    }
    else {
        $self->log->debug("Template '$template' not found");

        $res->status(404);
        $res->body('404 Not Found');
    }

    return $res->finalize;
}

1;
