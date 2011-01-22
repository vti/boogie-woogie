package BoogieWoogie::Logger;

use Boose;

has 'env' => sub { {} };

sub debug { shift->_log('debug', @_) }
sub info  { shift->_log('info',  @_) }
sub warn  { shift->_log('warn',  @_) }
sub error { shift->_log('debug', @_) }
sub fatal { shift->_log('fatal', @_) }

sub _log {
    my $self = shift;

    if (my $logger = $self->env->{'psgix.logger'}) {
        my ($level, $message) = @_;

        $logger->({level => $level, message => $message});
    }
}

1;
