#!/usr/bin/env perl

use lib 't/lib';

use TestLoader qw(t/routes_dispatcher);

Test::Class->runtests;
