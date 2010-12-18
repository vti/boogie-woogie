package BoogieWoogie::Logger::Base;
use Boose;
extends 'Boose::Base';

has 'logger';

sub debug { shift->_log('debug', @_) }
sub info  { shift->_log('info',  @_) }
sub warn  { shift->_log('warn',  @_) }
sub error { shift->_log('debug', @_) }
sub fatal { shift->_log('fatal', @_) }

sub _log { }

1;
