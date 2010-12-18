package BoogieWoogie::Logger;
use Boose;
extends 'BoogieWoogie::Logger::Base';

my $ESCAPE = pack('C', 0x1B);

sub _log {
    my $self = shift;
    my ($level, $message) = @_;

    if ($ENV{BOOGIE_WOOGIE_LOG_COLORS} && $level eq 'warn') {
        $message = "$ESCAPE\[31m$message$ESCAPE\[0m";
    }

    $self->logger->({level => $level, message => $message});
}

1;
