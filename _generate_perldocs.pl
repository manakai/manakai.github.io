use strict;
use warnings;
use Path::Tiny;

my $DEBUG = $ENV{DEBUG} || 0;

my $RootPath = path (__FILE__)->parent;

my $repos_path = $RootPath->child ('local/repos');
system 'rm', '-fr', $repos_path unless $DEBUG;

my $docs_path = $RootPath->child ('pod');
$docs_path->remove_tree;

my @repo = qw(wakaba/perl-charclass
              manakai/perl-web-dom manakai/perl-web-markup
              manakai/perl-web-encodings manakai/perl-web-css
              manakai/perl-web-url manakai/perl-web-datetime
              manakai/perl-web-resource manakai/perl-web-langtag
              manakai/perl-web-js wakaba/testdataparser
              manakai/perl-web-driver-client
              manakai/webhacc-cli);
for my $name (@repo) {
  (system ('git', 'clone', "https://github.com/$name", $repos_path->child ($name)) == 0) or ($DEBUG or die $?);
}

unshift our @INC,
    $repos_path->child ('wakaba/perl-charclass/lib')->stringify,
    $repos_path->child ('manakai/perl-web-dom/lib')->stringify,
    $repos_path->child ('manakai/perl-web-markup/lib')->stringify,
    $repos_path->child ('manakai/perl-web-encodings/lib')->stringify;
require Web::DOM::Document;

require "_pod2html_common.pl";
sub pod2html ($$$%);
sub text2html ($$$%);

my $ModuleDocURL = {
  Encode => q<https://search.cpan.org/dist/Encode/Encode.pm>,
  Exporter => q<https://search.cpan.org/dist/Exporter/lib/Exporter.pm>,
  JE => q<https://search.cpan.org/dist/JE/lib/JE.pm>,
  'Time::Local' => q<https://search.cpan.org/dist/Time-Local/lib/Time/Local.pm>,
  'Time::Piece' => q<https://search.cpan.org/dist/Time-Piece/Piece.pm>,
  DateTime => q<https://search.cpan.org/dist/DateTime/lib/DateTime.pm>,
  'Regexp::Parser' => q<https://search.cpan.org/dist/Regexp-Parser/lib/Regexp/Parser.pm>,

  'Whatpm::HTML' => q<https://manakai.github.io/pod/Web/HTML/Parser>,
  'Message::DOM::Document' => q<https://manakai.github.io/pod/Web/DOM/Document>,
  'Message::DOM::Element' => q<https://manakai.github.io/pod/Web/DOM/Element>,
};

sub node2html ($$$%) {
  my ($node, $root_url => $html_path, %args) = @_;
  my $repo_short = [split m{/}, $args{repo} // '']->[-1];
  my $doc = new Web::DOM::Document;
  $doc->manakai_is_html (1);
  $doc->inner_html (qq{
    <!DOCTYPE html>
    <html lang=en>
      <meta charset=utf-8>
      <link rel=stylesheet href="">
      <meta name=viewport content="width=device-width">

      <h1><a href="$root_url" rel=top></a></h1>
  });
  $doc->head->children->[1]->href ($args{css_url} // "$root_url/css/pod.css");
  $doc->title ($args{module_name});
  $doc->body->last_element_child->last_element_child->text_content
      ($args{site_title});
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

sub main () {
  my $site_title = q{The manakai project};
  my $css_url = undef;

  my $to_module_url = sub {
    my ($root_url, $module) = @_;
    return $ModuleDocURL->{$module} // do {
      $module =~ s{::}{/}g;
      "$root_url/pod/$module";
    };
  };
  my $to_repo_url = sub {
    my ($root_url, $repo) = @_;
    return "$root_url/pod/$repo";
  };
  
  my $write = sub {
    my ($node, $root_url => $html_path, %args) = @_;
    node2html $node, $root_url, $html_path, %args,
        site_title => $site_title,
        css_url => $css_url;
  };
  
  my $modules = {};
  for my $repo (@repo) {
    my $repo_path = $repos_path->child ($repo);
    my $repo_short = [split m{/}, $repo]->[-1];
    $modules->{$repo_short} ||= {};

    my $readme_path = $repo_path->child ('README.pod');
    my $html_path = $docs_path->child ($repo_short . '.html');
    if ($readme_path->is_file) {
      pod2html $readme_path->slurp_utf8 => $html_path, $write,
          to_repo_url => $to_repo_url, to_module_url => $to_module_url,
          module_name => $repo_short,
          repo => $repo,
          source_path => 'README.pod';
    } else {
      $readme_path = $repo_path->child ('README');
      if (-f $readme_path) {
        text2html $readme_path->slurp_utf8 => $html_path, $write,
            module_name => $repo_short,
            repo => $repo,
            source_path => 'README';
      } else {
        text2html '' => $html_path, $write,
            module_name => $repo_short,
            repo => $repo,
            source_path => '';
      }
    }

  {
    my $has_pod = {};
    my $lib_path = $repo_path->child ('lib');
    my $iter = $lib_path->iterator ({recurse => 1});
    while (my $x = $iter->()) {
      next unless $x =~ /\.(?:pm|pod)$/;
      my $path = $x->relative ($lib_path);
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
        pod2html $pod_path->slurp_utf8 => $html_path, $write,
            to_repo_url => $to_repo_url, to_module_url => $to_module_url,
            module_name => $module_name,
            repo => $repo,
            source_path => 'lib/' . $_ . ($has_pod->{$_}->{pm} ? '.pm' : '.pod');
      } # $has_pod
    }

  {
    my $has_pod = {};
    my $bin_path = $repo_path->child ('bin');
    my $iter = $bin_path->iterator ({recurse => 1});
    while (my $x = $iter->()) {
      next unless $x =~ /\.(?:pl|pod)$/;
      my $path = $x->relative ($bin_path);
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
        pod2html $pod_path->slurp_utf8 => $html_path, $write,
            to_repo_url => $to_repo_url, to_module_url => $to_module_url,
            module_name => $module_name,
            repo => $repo,
            source_path => 'bin/' . $_ . ($has_pod->{$_}->{pl} ? '.pl' : '.pod');
      } # $has_pod
    }
  } # @repo

{
  my $root_url = q{..};
  my $doc = new Web::DOM::Document;
  $doc->manakai_is_html (1);
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
    $write->($ul, $root_url => $html_path,
             module_name => 'Module documents',
             repo => undef,
             source_path => undef);
  }
} # main

main;

=head1 LICENSE

Copyright 2014-2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
