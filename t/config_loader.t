#!/usr/bin/env perl

use lib 't/lib';

use TestLoader qw(t/config_loader);

Test::Class->runtests;
