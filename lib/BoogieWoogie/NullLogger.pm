package BoogieWoogie::NullLogger;
use Boose;
extends 'BoogieWoogie::Logger::Base';

sub debug { }
sub info  { }
sub warn  { }
sub error { }
sub fatal { }

1;
