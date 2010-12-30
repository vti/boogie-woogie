#!/usr/bin/env perl

use lib 't/lib';

use TestLoader qw(t/controller);

Test::Class->runtests;
