package BoogieWoogie::Util;

use strict;
use warnings;

use base 'Exporter';

use vars qw(@EXPORT @EXPORT_OK $VERSION @ISA);

@EXPORT = @EXPORT_OK = qw(camelize decamelize);

sub camelize {
    my $string = shift;

    return unless $string;

    my @parts;
    foreach my $module (split '-' => $string) {
        push @parts, join '' => map {ucfirst} split _ => $module;
    }

    return join '::' => @parts;
}

sub decamelize {
    my $string = shift;

    my @parts;
    foreach my $module (split '::' => $string) {
        my @tokens = split '([A-Z])' => $module;
        my @p;
        foreach my $token (@tokens) {
            next unless defined $token && $token ne '';

            if ($token =~ m/[A-Z]/) {
                push @p, lc $token;
            }
            else {
                $p[-1] .= $token;
            }
        }

        push @parts, join _ => @p;
    }

    return join '-' => @parts;
}

1;
