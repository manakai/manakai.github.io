use strict;
use warnings;
use Path::Tiny;
use Pod::Simple::HTML;

my $DEBUG = 0;

my $repos_path = path (__FILE__)->parent->child ('local/repos');
system 'rm', '-fr', $repos_path unless $DEBUG;

my $docs_path = path (__FILE__)->parent->child ('pod');
$docs_path->remove_tree;

my @repo = qw(wakaba/perl-charclass
              manakai/perl-web-dom manakai/perl-web-markup
              manakai/perl-web-encodings manakai/perl-web-css
              manakai/perl-web-url manakai/perl-web-datetime
              manakai/perl-web-resource manakai/perl-web-langtag
              manakai/perl-web-js wakaba/testdataparser
              manakai/webhacc-cli);
for my $name (@repo) {
  (system ('git', 'clone', "git://github.com/$name", $repos_path->child ($name)) == 0) or ($DEBUG or die $?);
}

unshift our @INC,
    $repos_path->child ('wakaba/perl-charclass/lib')->stringify,
    $repos_path->child ('manakai/perl-web-dom/lib')->stringify,
    $repos_path->child ('manakai/perl-web-markup/lib')->stringify,
    $repos_path->child ('manakai/perl-web-encodings/lib')->stringify;
require Web::DOM::Document;
require Web::HTML::Parser;

my $ModuleDocURL = {
  Encode => q<http://search.cpan.org/dist/Encode/Encode.pm>,
  Exporter => q<http://search.cpan.org/dist/Exporter/lib/Exporter.pm>,
  JE => q<http://search.cpan.org/dist/JE/lib/JE.pm>,
  'Time::Local' => q<http://search.cpan.org/dist/Time-Local/lib/Time/Local.pm>,
  'Time::Piece' => q<http://search.cpan.org/dist/Time-Piece/Piece.pm>,
  DateTime => q<http://search.cpan.org/dist/DateTime/lib/DateTime.pm>,
  'Regexp::Parser' => q<http://search.cpan.org/dist/Regexp-Parser/lib/Regexp/Parser.pm>,

  'Whatpm::HTML' => q<http://manakai.github.io/pod/Web/HTML/Parser>,
  'Message::DOM::Document' => q<http://manakai.github.io/pod/Web/DOM/Document>,
  'Message::DOM::Element' => q<http://manakai.github.io/pod/Web/DOM/Element>,
};

sub process_inline_nodes ($$@) {
  my ($doc, $root_url, @source) = @_;
  my @dest;
  while (@source) {
    my $source = shift @source;
    if ($source->node_type == $source->ELEMENT_NODE) {
      my $ln = $source->local_name;
      if ($ln eq 'a') {
        my $url = $source->get_attribute ('href');
        if (defined $url and
            $url =~ m{^http://search.cpan.org/perldoc\?([^#]+)(#.*|)$}s) {
          my $module = $1;
          my $suffix = $2;
          $module =~ s/%3A%3A/::/g;
          $url = $ModuleDocURL->{$module} // do {
            $module =~ s{::}{/}g;
            "$root_url/pod/$module";
          };
          $source->set_attribute (href => "$url$suffix");
          push @dest, $source;
        } elsif (not defined $url and $source->text_content eq '') {
          #
        } else {
          push @dest, $source;
        }
      } elsif ($ln eq 'i') {
        my $var = $doc->create_element ('var');
        $var->append_child ($_) for $source->child_nodes->to_list;
        push @dest, $var;
      } else {
        push @dest, $source;
      }
    } elsif ($source->node_type == $source->TEXT_NODE) {
      my $text = $source->data;
      my @cite;
      while ($text =~ s/\s*\[([^\[\]]+)\]\s*$//) {
        unshift @cite, $1;
      }
      for (split /(<[^<>]+>|[Tt]he\s+perl-\S+\s+package)/, $text) {
        if (m{^<((?:https?|view-source):[^<>]+)>$}) {
          my $a = $doc->create_element ('a');
          $a->href ($1);
          $a->text_content ($1);
          my $code = $doc->create_element ('code');
          $code->class_name ('url');
          $code->manakai_append_text ('<');
          $code->append_child ($a);
          $code->manakai_append_text ('>');
          push @dest, $code;
        } elsif (/([Tt]he\s+(perl-\S+)\s+package)/) {
          my $a = $doc->create_element ('a');
          $a->href ("$root_url/pod/$2");
          $a->text_content ($1);
          push @dest, $a;
        } else {
          push @dest, $doc->create_text_node ($_);
        }
      }
      for (@cite) {
        push @dest, $doc->create_text_node (' ');
        my $cite = $doc->create_element ('cite');
        $cite->class_name ('ref');
        $cite->manakai_append_text ('[');
        my $a = $doc->create_element ('a');
        $a->href ('#' . $_);
        $a->text_content ($_);
        $cite->append_child ($a);
        $cite->manakai_append_text (']');
        push @dest, $cite;
      }
    }
  }
  return @dest;
} # process_inline_nodes

sub node2html ($$$%) {
  my ($node, $root_url => $html_path, %args) = @_;
  my $repo_short = [split m{/}, $args{repo} // '']->[-1];
  my $doc = new Web::DOM::Document;
  $doc->manakai_is_html (1);
  $doc->inner_html (qq{
    <!DOCTYPE html>
    <html lang=en>
      <meta charset=utf-8>
      <link rel=stylesheet href="$root_url/css/pod.css">
      <meta name=viewport content="width=device-width">

      <h1><a href="$root_url" rel=top>The manakai project</a></h1>
  });
  $doc->title ($args{module_name});
  if (not defined $repo_short) {
    my $nav = $doc->create_element ('nav');
    $nav->class_name ('breadcrumb');
    $nav->inner_html (qq{
      <ul>
        <li><a href="$root_url/docs" rel=up>Documents</a></li>
        <li><a href="$root_url/pod/#modules" rel=bookmark>Perl modules</a></li>
      </ul>
    });
    $doc->body->append_child ($nav);
  } elsif ($args{module_name} eq $repo_short) {
    my $nav = $doc->create_element ('nav');
    $nav->class_name ('breadcrumb');
    $nav->inner_html (qq{
      <ul>
        <li><a href="$root_url/docs" rel="up up">Documents</a></li>
        <li><a href="$root_url/pod/#modules" rel=up>Perl modules</a></li>
        <li><a href="" rel=bookmark></a></li>
      </ul>
    });
    my $ul = $nav->last_element_child;
    $ul->last_element_child->last_element_child->text_content ($args{module_name});

    my $ul2 = $doc->create_element ('ul');
    $ul2->class_name ('pod-source');
    $ul2->inner_html (q{<li><a>Source</a>});
    $ul2->first_child->first_child->href ("https://github.com/$args{repo}/tree/master/$args{source_path}");
    $nav->append_child ($ul2);
    $doc->body->append_child ($nav);
  } else {
    my $nav = $doc->create_element ('nav');
    $nav->class_name ('breadcrumb');
    $nav->inner_html (qq{
      <ul>
        <li><a href="$root_url/docs" rel="up up up">Documents</a></li>
        <li><a href="$root_url/pod/#modules" rel="up up">Perl modules</a></li>
        <li><a href="" rel=up></a></li>
        <li><a href="" rel=bookmark></a></li>
      </ul>
    });
    my $ul = $nav->last_element_child;
    my $up_a = $ul->last_element_child->previous_element_sibling->last_element_child;
    $up_a->href ("$root_url/pod/$repo_short");
    $up_a->text_content ($repo_short);
    $ul->last_element_child->last_element_child->text_content ($args{module_name});

    my $ul2 = $doc->create_element ('ul');
    $ul2->class_name ('pod-source');
    $ul2->inner_html (q{<li><a>Source</a>});
    $ul2->first_child->first_child->href ("https://github.com/$args{repo}/tree/master/$args{source_path}");
    $nav->append_child ($ul2);
    $doc->body->append_child ($nav);
  }

  my $article = $doc->create_element ('article');
  $article->append_child ($node);
  $doc->body->append_child ($article);

  my $link = $doc->create_element ('link');
  $link->rel ('license');
  if ($doc->get_element_by_id ('LICENSE')) {
    $link->href ('#LICENSE');
  } else {
    $link->href ("$root_url/contact#license");
  }
  $doc->head->append_child ($link);

  my $footer = $doc->create_element ('footer');
  $footer->inner_html (qq{
  <p>The manakai project since 2002
  <ul>
    <li><a href="$root_url" rel=top>Top</a>
    <li><a href="$root_url/contact">Contact</a>
  </ul>
<script>
(function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
(i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
})(window,document,'script','//www.google-analytics.com/analytics.js','ga');
ga('create', 'UA-39820773-4', 'manakai.github.io');
ga('send', 'pageview');
</script>
  });
  $doc->body->append_child ($footer);

  $html_path->parent->mkpath;
  $html_path->spew_utf8 ($doc->inner_html);
} # node2html

sub pod2html ($$%) {
  my ($pod_path => $html_path, %args) = @_;
  my $n = 0;
  $n++ while $args{module_name} =~ /::/g;
  $n++ if $html_path =~ m{/index.html$};
  my $root_url = join '/', (('..') x (1 + $n));

  my $p = Pod::Simple::HTML->new;
  $p->output_string (\my $html);
  $p->parse_characters (1);
  $p->parse_string_document ($pod_path->slurp_utf8);

  my $source_doc = new Web::DOM::Document;
  my $parser = new Web::HTML::Parser;
  $parser->onerror (sub { });
  $parser->parse_byte_string (undef, $html => $source_doc);

  my $doc = new Web::DOM::Document;
  $doc->manakai_is_html (1);

  my $body = $doc->create_document_fragment;
  my $section1 = $body;
  my $section2 = $body;
  my $section3 = $body;
  my $section4 = $body;
  my $last_section = $body;
  my $has_section = {};
  my $has_member = {};

  my $source_body = $source_doc->body;
  for my $source_node (@{$source_body->child_nodes}) {
    my $nt = $source_node->node_type;
    if ($nt == $source_node->ELEMENT_NODE) {
      my $ln = $source_node->local_name;
      if ($ln eq 'h1' or $ln eq 'h2' or $ln eq 'h3' or $ln eq 'h4') {
        my $section = $doc->create_element ('section');
        my @node = $source_node->child_nodes->to_list;
        if (@node and
            $node[0]->node_type == $source_node->ELEMENT_NODE and
            $node[0]->local_name eq 'a') {
          my $name = $node[0]->name;
          $section->id ($name) if length $name;
          $has_section->{$name} = 1;
          my @child = $node[0]->child_nodes->to_list;
          shift @node;
          unshift @node, @child;
        }
        my $h1 = $doc->create_element ('h1');
        $h1->append_child ($_) for @node;
        $section->append_child ($h1);
        if ($ln eq 'h1') {
          $body->append_child ($section);
          $last_section = $section1 = $section2 = $section3 = $section4
              = $section;
        } elsif ($ln eq 'h2') {
          $section1->append_child ($section);
          $last_section = $section2 = $section3 = $section4 = $section;
        } elsif ($ln eq 'h3') {
          $section2->append_child ($section);
          $last_section = $section3 = $section4 = $section;
        } elsif ($ln eq 'h4') {
          $section3->append_child ($section);
          $last_section = $section4 = $section;
        }
      } elsif ($ln eq 'p') {
        if ($source_node->child_nodes->length == 1 and
            $source_node->first_child->node_type == $source_node->TEXT_NODE) {
          my $text = $source_node->inner_html;
          if ($text =~ s{^([A-Za-z0-9_:]+) - }{}) {
            my $p = $doc->create_element ('p');
            $p->inner_html (qq{<code>$1</code>});
            $last_section->append_child ($p);
          }
          $text =~ s{DOM\s+\|([A-Za-z0-9]+)\|\s+([Ii]nterface|[Oo]bject)}
                    {DOM <a href="http://suika.suikawiki.org/~wakaba/wiki/sw/n/$1"><code>$1</code></a> $2}g;
          $text =~ s{\|([^|]+)\|}{<code>$1</code>}g;
          $source_node->inner_html ($text);
        }
        my $p = $doc->create_element ('p');
        $p->append_child ($_)
            for process_inline_nodes
                ($doc, $root_url, $source_node->child_nodes->to_list);
        $last_section->append_child ($p);
      } elsif ($ln eq 'dl') {
        my $dl = $doc->create_element ('dl');
        my $has_dd;
        for my $src_node ($source_node->child_nodes->to_list) {
          if ($src_node->node_type == $src_node->ELEMENT_NODE) {
            my $ln = $src_node->local_name;
            if ($ln eq 'dt') {
              if ($src_node->child_nodes->length == 1 and
                  $src_node->first_child->node_type == $src_node->ELEMENT_NODE and
                  $src_node->first_child->local_name eq 'a') {
                my $dt = $doc->create_element ('dt');
                $dt->inner_html ('<code></code>')
                    if $src_node->text_content =~ /\$|->|=>/;
                $dt->id ($src_node->first_child->name);
                my $code = $dt->first_child || $dt;
                if ($src_node->first_child->child_nodes->length == 1 and
                    $src_node->first_child->first_child->node_type == $src_node->TEXT_NODE) {
                  my $text = $src_node->first_child->text_content;
                  if ($text =~ /^(.*->)(\S+)(.*)$/s) {
                    $code->manakai_append_text ($1);
                    my $strong = $doc->create_element ('strong');
                    $strong->id ("member-$2") unless $has_member->{$2}++;
                    $strong->text_content ($2);
                    $code->append_child ($strong);
                    $code->manakai_append_text ($3);
                  } elsif ($text =~ /^(.*)\b(new\s+\S+)(.*)$/s) {
                    $code->manakai_append_text ($1);
                    my $strong = $doc->create_element ('strong');
                    $strong->id ("member-new") unless $has_member->{new}++;
                    $strong->text_content ($2);
                    $code->append_child ($strong);
                    $code->manakai_append_text ($3);
                  } else {
                    $code->text_content ($text);
                  }
                } else {
                  $code->append_child ($_)
                      for $src_node->first_child->child_nodes->to_list;
                }
                $dl->append_child ($dt);
              } else {
                my $dt = $doc->create_element ('dt');
                $dt->append_child ($_)
                    for process_inline_nodes
                        ($doc, $root_url, $src_node->child_nodes->to_list);
                $dl->append_child ($dt);
              }
            } elsif ($ln eq 'dd') {
              if ($src_node->child_nodes->length == 1 and
                  $src_node->first_child->node_type == $src_node->TEXT_NODE and
                  not $src_node->first_child->data =~ /\S/) {
                #
              } else {
                my $dd = $doc->create_element ('dd');
                for ($src_node->child_nodes->to_list) {
                  if ($_->node_type == $_->ELEMENT_NODE and
                      $_->local_name eq 'p') {
                    my $p = $doc->create_element ('p');
                    $p->append_child ($_)
                        for process_inline_nodes
                            ($doc, $root_url, $_->child_nodes->to_list);
                    $dd->append_child ($p);
                  } elsif ($_->node_type == $_->ELEMENT_NODE and
                           $_->local_name eq 'pre') {
                    my $pre = $doc->create_element ('pre');
                    my $code = $pre->append_child ($doc->create_element ('code'));
                    $code->append_child ($_) for $_->child_nodes->to_list;
                    $dd->append_child ($pre);
                  } else {
                    $dd->append_child ($_);
                  }
                }
                $dl->append_child ($dd);
                $has_dd = 1;
              }
            } else {
              $dl->append_child ($src_node);
            }
          } else {
            $dl->append_child ($src_node);
          }
        }
        if ($has_dd) {
          $last_section->append_child ($dl);
        } else {
          my $ul = $doc->create_element ('ul');
          for ($dl->child_nodes->to_list) {
            if ($_->node_type == $_->ELEMENT_NODE and
                $_->local_name eq 'dt') {
              my $li = $doc->create_element ('li');
              $li->append_child ($_) for $_->child_nodes->to_list;
              $ul->append_child ($li);
            } else {
              $ul->append_child ($_);
            }
          }
          $last_section->append_child ($ul);
        }
      } elsif ($ln eq 'pre') {
        my $pre = $doc->create_element ('pre');
        my $code = $pre->append_child ($doc->create_element ('code'));
        $code->append_child ($_) for $source_node->child_nodes->to_list;
        $last_section->append_child ($pre);
      } elsif ($ln eq 'a') {
        $last_section->append_child ($_) for $source_node->child_nodes->to_list;
      } else {
        $last_section->append_child ($source_node);
      }
    } elsif ($nt == $source_node->TEXT_NODE) {
      $last_section->append_child ($source_node);
    }
  }

  my $name = $body->get_elements_by_tag_name ('section')->[0];
  if (defined $name and
      $name->id eq 'NAME' and
      $name->children->length == 3 and
      $name->children->[0]->local_name eq 'h1' and
      $name->children->[1]->local_name eq 'p' and
      $name->children->[2]->local_name eq 'p') {
    my $h = $doc->create_element ('hgroup');
    $h->inner_html (q{<h1></h1><h2></h2>});
    $h->first_child->append_child ($_)
        for $name->children->[1]->child_nodes->to_list;
    $h->last_child->append_child ($_)
        for $name->children->[2]->child_nodes->to_list;
    $body->replace_child ($h, $name);
  }

  node2html $body, $root_url => $html_path, %args;
} # pod2html

sub text2html ($$%) {
  my ($text => $html_path, %args) = @_;
  my $n = 0;
  $n++ while $args{module_name} =~ /::/g;
  $n++ if $html_path =~ m{/index.html$};
  my $root_url = join '/', (('..') x (1 + $n));
  my $doc = new Web::DOM::Document;
  my $pre = $doc->create_element ('pre');
  $pre->text_content ($text);
  node2html $pre, $root_url => $html_path, %args;
} # text2html

my $modules = {};
for my $repo (@repo) {
  my $repo_path = $repos_path->child ($repo);
  my $repo_short = [split m{/}, $repo]->[-1];
  $modules->{$repo_short} ||= {};

  my $readme_path = $repo_path->child ('README.pod');
  my $html_path = $docs_path->child ($repo_short . '.html');
  if ($readme_path->is_file) {
    pod2html $readme_path => $html_path,
        module_name => $repo_short,
        repo => $repo,
        source_path => 'README.pod';
  } else {
    $readme_path = $repo_path->child ('README');
    if (-f $readme_path) {
      text2html $readme_path->slurp_utf8 => $html_path,
          module_name => $repo_short,
          repo => $repo,
          source_path => 'README';
    } else {
      text2html '' => $html_path,
          module_name => $repo_short,
          repo => $repo,
          source_path => '';
    }
  }

  {
    my $has_pod = {};
    my $lib_path = $repo_path->child ('lib');
    my $iter = $lib_path->iterator ({recurse => 1});
    while (my $_ = $iter->()) {
      next unless /\.(?:pm|pod)$/;
      my $path = $_->relative ($lib_path);
      my $name = $path->stringify;
      $name =~ s/\.(pm|pod)$//;
      $has_pod->{$name}->{$1} = $1;
    }

    for (keys %$has_pod) {
      my $pod_path = $lib_path->child ($_ . ($has_pod->{$_}->{pod} ? '.pod' : '.pm'));
      my $html_path = $docs_path->child ($_ . '.html');
      $html_path = $docs_path->child ("$_/index.html")
          if $lib_path->child ($_)->is_dir;
      my $module_name = $_;
      $module_name =~ s{/}{::}g;
      $modules->{$repo_short}->{$module_name} = $_;
      
      warn "$module_name...\n";
      pod2html $pod_path => $html_path,
          module_name => $module_name,
          repo => $repo,
          source_path => 'lib/' . $_ . ($has_pod->{$_}->{pm} ? '.pm' : '.pod');
    } # $has_pod
  }

  {
    my $has_pod = {};
    my $bin_path = $repo_path->child ('bin');
    my $iter = $bin_path->iterator ({recurse => 1});
    while (my $_ = $iter->()) {
      next unless /\.(?:pl|pod)$/;
      my $path = $_->relative ($bin_path);
      my $name = $path->stringify;
      $name =~ s/\.(pl|pod)$//;
      $has_pod->{$name}->{$1} = $1;
    }

    for (keys %$has_pod) {
      my $pod_path = $bin_path->child ($_ . ($has_pod->{$_}->{pod} ? '.pod' : '.pl'));
      my $html_path = $docs_path->child ($_ . '.html');
      $html_path = $docs_path->child ("$_/index.html")
          if $bin_path->child ($_)->is_dir;
      my $module_name = $_;
      $module_name =~ s/\.pl$//;
      $modules->{$repo_short}->{$module_name} = $_;
      
      warn "$module_name...\n";
      pod2html $pod_path => $html_path,
          module_name => $module_name,
          repo => $repo,
          source_path => 'bin/' . $_ . ($has_pod->{$_}->{pl} ? '.pl' : '.pod');
    } # $has_pod
  }
} # @repo

{
  my $root_url = q{..};
  my $doc = new Web::DOM::Document;
  my $ul = $doc->create_element ('ul');
  $ul->id ('modules');
  for my $repo_short (sort { $a cmp $b } keys %$modules) {
    next if $repo_short eq 'perl-charclass';
    my $a_el = $doc->create_element ('a');
    $a_el->href ("$root_url/pod/$repo_short");
    $a_el->text_content ($repo_short);
    my $li = $doc->create_element ('li');
    $li->append_child ($a_el);
    my $sub_ul = $doc->create_element ('ul');
    for my $module (sort { $a cmp $b } keys %{$modules->{$repo_short}}) {
      my $li = $doc->create_element ('li');
      my $a_el = $doc->create_element ('a');
      $a_el->href ("$root_url/pod/$modules->{$repo_short}->{$module}");
      $a_el->text_content ($module);
      $li->append_child ($a_el);
      $sub_ul->append_child ($li);
    }
    $li->append_child ($sub_ul) if $sub_ul->has_child_nodes;
    $ul->append_child ($li);
  }
  my $html_path = $docs_path->child ('index.html');
  node2html $ul, $root_url => $html_path,
        module_name => 'Module documents',
        repo => undef,
        source_path => undef;
}
