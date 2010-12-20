use strict;
use warnings;

use Test::More tests => 12;

use BoogieWoogie::Util;

is(camelize('hello'),            'Hello');
is(camelize('hello_there'),      'HelloThere');
is(camelize('hello_there-here'), 'HelloThere::Here');
is(camelize('a_b_c'),            'ABC');

is(decamelize('Hello'),            'hello');
is(decamelize('HelloThere'),       'hello_there');
is(decamelize('HelloThere::Here'), 'hello_there-here');
is(decamelize('ABC'),              'a_b_c');

ok not defined slurp('unlikelytoexist');
ok not defined slurp();
ok not defined slurp('');
ok slurp('t/util.t');
