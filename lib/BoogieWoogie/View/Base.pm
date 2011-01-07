package BoogieWoogie::View::Base;
use Boose;

use File::Spec;
use BoogieWoogie::Util qw/decamelize slurp/;

our $LEADING_SPACE  = qr/(?:\n [ ]*)?/x;
our $TRAILING_SPACE = qr/(?:[ ]* \n)?/x;
our $START_TAG      = qr/{{/x;
our $END_TAG        = qr/}}/x;

our $START_OF_PARTIAL          = quotemeta '>';
our $START_OF_SECTION          = quotemeta '#';
our $START_OF_INVERTED_SECTION = quotemeta '^';
our $END_OF_SECTION            = quotemeta '/';

use constant TEXT => 1;
use constant TAG  => 1;

has 'app' => {is_weak => 1};
has 'format' => 'html';
has 'templates_path' => sub { $_[0]->app->home->reldir('views') };

sub render {
    my $self = shift;

    my $template;
    my $context;

    if (@_ == 0) {
        $template = $self->_slurp_template($self->_class_to_template);
        $context  = $self->to_hash;
    }
    else {
        $template = shift;
        $context  = shift;
    }

    my $output = '';

    pos $template = 0;
    while (pos $template < length $template) {
        if ($template =~ m/($LEADING_SPACE)?\G $START_TAG /gcxms) {
            my $chunk = '';

            my $leading_newline = !!$1;

            # Tripple
            if ($template =~ m/\G { (.*?) } $END_TAG/gcxms) {
                $chunk .= $self->_render_tag($1, $context);
            }

            # Comment
            elsif ($template =~ m/\G ! .*? $END_TAG/gcxms) {
            }

            # Section
            elsif ($template
                =~ m/\G $START_OF_SECTION (.*?) $END_TAG ($TRAILING_SPACE)?/gcxms
              )
            {
                my $name = $1;

                if ($template
                    =~ m/\G (.*?) ($LEADING_SPACE)? $START_TAG $END_OF_SECTION $name $END_TAG ($TRAILING_SPACE)?/gcxms
                  )
                {
                    $chunk .= $self->_render_section($name, $1, $context);
                }
                else {
                    throw("Section's '$name' end not found");
                }
            }

            # Inverted section
            elsif ($template
                =~ m/\G $START_OF_INVERTED_SECTION (.*?) $END_TAG ($TRAILING_SPACE)?/gcxms
              )
            {
                my $name = $1;

                if ($template
                    =~ m/ \G (.*?) ($LEADING_SPACE)? $START_TAG $END_OF_SECTION $name $END_TAG ($TRAILING_SPACE)?/gcxms
                  )
                {
                    $chunk
                      .= $self->_render_inverted_section($name, $1, $context);
                }
                else {
                    throw("Section's '$name' end not found");
                }
            }

            # End of section
            elsif ($template =~ m/\G $END_OF_SECTION (.*?) $END_TAG/gcxms) {
                throw("Unexpected end of section '$1'");
            }

            # Partial
            elsif ($template =~ m/\G $START_OF_PARTIAL (.*?) $END_TAG/gcxms) {
                $chunk .= $self->_render_partial($1, $context);
            }

            # Tag
            elsif ($template =~ m/\G (.*?) $END_TAG/gcxms) {
                $chunk .= $self->_render_tag_escaped($1, $context);
            }
            else {
                throw("Can't find where tag is closed");
            }

            if ($chunk ne '') {
                $output .= $chunk;
            }
            elsif ($output eq '' || $leading_newline) {
                if ($template =~ m/\G $TRAILING_SPACE/gcxms) {
                    $output =~ s/[ ]*\z//xms;
                }
            }
        }

        # Text before tag
        elsif ($template =~ m/\G (.*?) (?=$START_TAG\{?)/gcxms) {
            $output .= $1;
        }

        # Other text
        else {
            $output .= substr($template, pos($template));
            last;
        }
    }

    return $output;
}

sub to_hash {
    my $self = shift;

    return {};
}

sub _render_tag {
    my $self    = shift;
    my $name    = shift;
    my $context = shift;

    return '' if $self->_is_empty($context, $name);

    my $value = $context->{$name};

    if (ref $value eq 'CODE') {
        return $self->render($value->($self, '', $context) // '', $context);
    }

    return $value;
}

sub _render_tag_escaped {
    my $self    = shift;
    my $tag     = shift;
    my $context = shift;

    my $do_not_escape;
    if ($tag =~ s/\A \&//xms) {
        $do_not_escape = 1;
    }

    my $output = $self->_render_tag($tag, $context);

    $output = $self->_escape($output) unless $do_not_escape;

    return $output;
}

sub _render_section {
    my $self     = shift;
    my $name     = shift;
    my $template = shift;
    my $context  = shift;

    return '' unless exists $context->{$name};

    my $value  = $context->{$name};
    my $output = '';

    if (ref $value eq 'HASH') {
        $output .= $self->render($template, $value);
    }
    elsif (ref $value eq 'ARRAY') {
        foreach my $el (@$value) {
            $output .= $self->render($template, $el);
        }
    }
    elsif (ref $value eq 'CODE') {
        $output
          .= $self->render($value->($self, $template, $context), $context);
    }
    elsif ($value) {
        $output .= $self->render($template, $context);
    }

    return $output;
}

sub _render_inverted_section {
    my $self     = shift;
    my $name     = shift;
    my $template = shift;
    my $context  = shift;

    return $self->render($template, $context)
      unless exists $context->{$name};

    my $value  = $context->{$name};
    my $output = '';

    if (ref $value eq 'HASH') {
    }
    elsif (ref $value eq 'ARRAY') {
        return '' if @$value;

        $output .= $self->render($template, $context);
    }
    elsif (!$value) {
        $output .= $self->render($template, $context);
    }

    return $output;
}

sub _render_partial {
    my $self     = shift;
    my $template = shift;
    my $context  = shift;

    my $content = $self->_slurp_template($template);

    return $self->render($content, $context);
}

sub _class_to_template {
    my $self = shift;

    my $class = ref $self;

    my $app_class = ref $self->app;
    $class =~ s/\A$app_class\:://xms;

    my $template = decamelize($class);
    $template .= '.' . $self->format if defined $self->format;

    return $template;
}

sub _slurp_template {
    my $self     = shift;
    my $template = shift;

    $template = File::Spec->catfile($self->templates_path, $template);

    my $content = slurp($template);

    throw("Can't open '$template'") unless defined $content;

    chomp $content;

    return $content;
}

sub _is_empty {
    my $self = shift;
    my ($vars, $var) = @_;

    return 1 unless exists $vars->{$var};
    return 1 unless defined $vars->{$var};
    return 1 if $vars->{$var} eq '';

    return 0;
}

sub _escape {
    my $self  = shift;
    my $value = shift;

    $value =~ s/&/&amp;/g;
    $value =~ s/</&lt;/g;
    $value =~ s/>/&gt;/g;
    $value =~ s/"/&quot;/g;

    return $value;
}

1;
