package BoogieWoogie::ConfigLoader;
use Boose;

use BoogieWoogie::Logger;

has 'home';
has 'file' => 'config';
has 'ext'  => 'pl';

has 'log' => sub { BoogieWoogie::Logger->new };

use Config::Any;
require File::Spec;

sub load {
    my $self = shift;

    my $file = $self->file . '.' . $self->ext;
    my $filepath = File::Spec->catfile($self->home, $file);

    my $config = Config::Any->load_files(
        {   files           => [$filepath],
            use_ext         => 1,
            flatten_to_hash => 1
        }
    );

    unless (%$config) {
        $self->log->debug("Config '$file' not found");
        return {};
    }

    $self->log->debug("Reading configuration from '$file'");
    return (values %$config)[0];
}

1;
