package ViewTest;

use strict;
use warnings;

use base 'Test::Class';

use Test::More;
use Try::Tiny;

use TestView;

sub _build_object { shift; TestView->new(@_) }

sub constructor : Test(1) {
    my $self = shift;

    my $renderer = $self->_build_object;
    ok $renderer;
}

sub variables : Test(19) {
    my $self = shift;

    my $renderer = $self->_build_object;

    my $output = $renderer->render('');
    is $output => '';

    $output = $renderer->render('foo');
    is $output => 'foo';

    $output = $renderer->render('Hello, {user}!');
    is $output => 'Hello, {user}!';

    $output = $renderer->render('Hello, {{user}}!');
    is $output => 'Hello, !';

    $output = $renderer->render('Hello, {{user}}!', {user => 'vti'});
    is $output => 'Hello, vti!';

    $output = $renderer->render("Hello\n{{user}}");
    is $output => "Hello\n";

    $output = $renderer->render("Hello{{user}}\nthere");
    is $output => "Hello\nthere";

    $output = $renderer->render("Hello\n   {{user}}   \nthere");
    is $output => "Hello\nthere";

    $output = $renderer->render('{{var}}', {var => 1});
    is $output => '1';

    $output = $renderer->render('{{var}}', {var => 0});
    is $output => '0';

    $output = $renderer->render('{{var}}', {var => ''});
    is $output => '';

    $output = $renderer->render('{{var}}', {var => undef});
    is $output => '';

    $output = $renderer->render('{{var}}', {var => '1 > 2'});
    is $output => '1 &gt; 2';

    $output = $renderer->render('{{&var}}', {var => '1 > 2'});
    is $output => '1 > 2';

    $output = $renderer->render('{{{var}}}', {var => '1 > 2'});
    is $output => '1 > 2';
}

sub comments : Test(5) {
    my $self = shift;

    my $renderer = $self->_build_object;

    my $output =
      $renderer->render('foo{{! Comment}}bar', {'! Comment' => 'ooops'});
    is $output => 'foobar';

    $output = $renderer->render("foo{{!\n Comment\n}}bar",
        {"!\n Comment\n" => 'ooops'});
    is $output => 'foobar';

    $output =
      $renderer->render("foo\n{{! Comment}}\nbar", {"! Comment" => 'ooops'});
    is $output => "foo\nbar";

    $output = $renderer->render("foo\n   {{! Comment}}\nbar",
        {"! Comment" => 'ooops'});
    is $output => "foo\nbar";

    $output =
      $renderer->render("foo {{! Comment}} bar", {"! Comment" => 'ooops'});
    is $output => "foo  bar";
}

sub sections : Test(8) {
    my $self = shift;

    my $renderer = $self->_build_object;

    my $output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => 1});
    is $output => 'Hello';

    $output = $renderer->render('{{#bool}}Hello{{/bool}}', {bool => 0});
    is $output => '';

    $output = $renderer->render("{{#bool}}\nHello\n{{/bool}}", {bool => 0});
    is $output => '';

    $output = $renderer->render("{{#bool}}\nHello\n{{/bool}}\n{{unknown}}",
        {bool => 0});
    is $output => '';

    $output =
      $renderer->render('{{#list}}{{n}}{{/list}}',
        {list => [{n => 1}, {n => 2}, {n => 3}]});
    is $output => '123';

    $output =
      $renderer->render('{{#list}}{{.}}{{/list}}', {list => [1, 2, 3]});
    is $output => '123';

    $output = $renderer->render('{{#list}}{{n}}{{/list}}', {list => []});
    is $output => '';

    $output = $renderer->render(
        '{{#s}}one{{/s}} {{#s}}{{two}}{{/s}} {{#s}}three{{/s}}',
        {s => 1, two => 'two'});
    is $output => 'one two three';
}

sub inverted_sections : Test(1) {
    my $self = shift;

    my $renderer = $self->_build_object;

    my $output = $renderer->render(<<'EOF', {repo => []});
{{#repo}}
  <b>{{name}}</b>
{{/repo}}
{{^repo}}
  No repos :(
{{/repo}}
EOF
    is $output => '  No repos :(';
}

sub lambdas : Test(6) {
    my $self = shift;

    my $renderer = $self->_build_object;

    my $output = $renderer->render(
        '{{lamda}}',
        {   lamda => sub { }
        }
    );
    is $output => '';

    $output = $renderer->render(
        '{{lamda}}',
        {   lamda => sub {0}
        }
    );
    is $output => '0';

    $output = $renderer->render(
        '{{lamda}}',
        {   lamda => sub {'text'}
        }
    );
    is $output => 'text';

    $output = $renderer->render(
        '{{lamda}}',
        {   lamda => sub {'{{var}}'},
            var   => 'text'
        }
    );
    is $output => 'text';

    $output = $renderer->render(
        '{{#lamda}}Hello{{/lamda}}',
        {   lamda => sub {'{{var}}'},
            var   => 'text'
        }
    );
    is $output => 'text';

    my $wrapped = sub {
        my $self = shift;
        my $text = shift;

        return '<b>' . $self->render($text, @_) . '</b>';
    };

    $output =
      $renderer->render(<<'EOF', {name => 'Willy', wrapped => $wrapped});
{{#wrapped}}
{{name}} is awesome.
{{/wrapped}}
EOF
    is $output => "<b>Willy is awesome.</b>";
}

sub partials : Test(3) {
    my $self = shift;

    my $renderer = $self->_build_object(templates_path => 't/view/templates');

    my $output = $renderer->render('{{>partial}}');
    is $output => 'Hello from partial!';

    $output =
      $renderer->render('{{>partial-with-directives}}', {name => 'foo'});
    is $output => 'Hello foo!';

    $output =
      $renderer->render('{{>partial-with-recursion}}', {name => 'foo'});
    is $output => '*Hello foo!*';
}

sub full : Test(1) {
    my $self = shift;

    my $renderer = $self->_build_object;

    my $output = $renderer->render(
        <<'EOF', {name => 'Chris', value => 10000, taxed_value => 10000 - (10000 * 0.4), in_ca => 1});
Hello {{name}}
You have just won ${{value}}!
{{#in_ca}}
Well, ${{taxed_value}}, after taxes.
{{/in_ca}}
EOF

    my $expected = <<'EOF';
Hello Chris
You have just won $10000!
Well, $6000, after taxes.
EOF
    chomp $expected;

    is $output => $expected;
}

sub class : Test(1) {
    my $self = shift;

    my $view = $self->_build_object(title => 'Hello', body => 'there!');
    $view->set_templates_path('t/view/templates');

    my $expected = <<'EOF';
<html>
    <head>
        <title>Hello</title>
    </head>
    <body>
        there!
    </body>
</html>
EOF
    chomp $expected;

    is $view->render => $expected;
}

1;
