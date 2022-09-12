use strict;
use warnings;
use Pod::Simple::HTML;
use Web::DOM::Document;
use Web::HTML::Parser;

sub process_inline_nodes ($$$$@) {
  my ($doc, $root_url, $to_repo_url, $to_module_url, @source) = @_;
  my @dest;
  while (@source) {
    my $source = shift @source;
    if ($source->node_type == $source->ELEMENT_NODE) {
      my $ln = $source->local_name;
      if ($ln eq 'a') {
        my $url = $source->get_attribute ('href');
        if (defined $url and
            $url =~ m{^https?://search.cpan.org/perldoc\?([^#]+)(#.*|)$}s) {
          my $module = $1;
          my $suffix = $2;
          $module =~ s/%3A%3A/::/g;
          $url = $to_module_url->($root_url, $module);
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
          $a->href ($to_repo_url->($root_url, $2));
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

sub pod2html ($$$%) {
  my ($pod_text => $html_path, $write, %args) = @_;
  my $n = 0;
  $n++ while $args{module_name} =~ /::/g;
  $n++ if $html_path =~ m{/index.html$};
  my $root_url = join '/', (('..') x (1 + $n));

  my $p = Pod::Simple::HTML->new;
  $p->output_string (\my $html);
  $p->parse_characters (1);
  $p->parse_string_document ($pod_text);

  my $source_doc = new Web::DOM::Document;
  my $parser = new Web::HTML::Parser;
  $parser->onerror (sub { });
  $parser->parse_char_string ($html => $source_doc);

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
                    {DOM <a href="https://suika.suikawiki.org/~wakaba/wiki/sw/n/$1"><code>$1</code></a> $2}g;
          $text =~ s{\|([^|]+)\|}{<code>$1</code>}g;
          $source_node->inner_html ($text);
        }
        my $p = $doc->create_element ('p');
        $p->append_child ($_)
            for process_inline_nodes
                    ($doc, $root_url, $args{to_repo_url}, $args{to_module_url},
                     $source_node->child_nodes->to_list);
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
                            ($doc, $root_url,
                             $args{to_repo_url}, $args{to_module_url},
                             $src_node->child_nodes->to_list);
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
                                ($doc, $root_url,
                                 $args{to_repo_url}, $args{to_module_url},
                                 $_->child_nodes->to_list);
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

  $write->($body, $root_url => $html_path, %args);
} # pod2html

sub text2html ($$$%) {
  my ($text => $html_path, $write, %args) = @_;
  my $n = 0;
  $n++ while $args{module_name} =~ /::/g;
  $n++ if $html_path =~ m{/index.html$};
  my $root_url = join '/', (('..') x (1 + $n));
  my $doc = new Web::DOM::Document;
  $doc->manakai_is_html (1);
  my $pre = $doc->create_element ('pre');
  $pre->text_content ($text);
  
  $write->($pre, $root_url => $html_path, %args);
} # text2html

1;

=head1 LICENSE

Copyright 2014-2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
