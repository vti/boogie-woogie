package BoogieWoogie::Logger;
use Boose;

extends 'Boose::Base';

has 'logger';

my $ESCAPE = pack('C', 0x1B);

sub debug { shift->_log('debug', @_) }
sub info  { shift->_log('info',  @_) }
sub warn  { shift->_log('warn',  @_) }
sub error { shift->_log('debug', @_) }
sub fatal { shift->_log('fatal', @_) }

sub _log {
    my $self = shift;
    my ($level, $message) = @_;

    if ($ENV{BOOGIE_WOOGIE_LOG_COLORS} && $level eq 'warn') {
        $message = "$ESCAPE\[31m$message$ESCAPE\[0m";
    }

    $self->logger->({level => $level, message => $message});
}

1;
