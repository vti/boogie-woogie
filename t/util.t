use strict;
use warnings;

use Test::More tests => 8;

use BoogieWoogie::Util;

is(camelize('hello'),            'Hello');
is(camelize('hello_there'),      'HelloThere');
is(camelize('hello_there-here'), 'HelloThere::Here');
is(camelize('a_b_c'),            'ABC');

is(decamelize('Hello'),            'hello');
is(decamelize('HelloThere'),       'hello_there');
is(decamelize('HelloThere::Here'), 'hello_there-here');
is(decamelize('ABC'),              'a_b_c');
