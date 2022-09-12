use strict;
use warnings;
use Path::Tiny;
use Web::DOM::Document;
use Web::Encoding;

require "_pod2html_common.pl";
sub pod2html ($$$%);
sub text2html ($$$%);

sub main (@) {
  my ($title, $in_file_name) = @_;
  die "Usage: $0 title pod-file\n" unless defined $in_file_name;

  $title = Web::Encoding::decode_web_utf8 ($title);
  
  my $pod_path = path ($in_file_name);
  my $module_name = '';
  my $html_path = '';

  $module_name = $in_file_name;
  $module_name =~ s{/}{::}g;
  $module_name =~ s{^.*?::}{};

  my $to_repo_url = sub {
    my ($root_url, $repo) = @_;
    return "$root_url/$repo";
  };
  my $to_module_url = sub {
    my ($root_url, $module) = @_;
    $module =~ s{::}{/}g;
    return "$root_url/$module";
  };
  
  my $write = sub {
    my ($node, $root_url => $html_path, %args) = @_;

    binmode STDOUT, qw(:encoding(utf-8));
    printf q{
      <!DOCTYPE HTML>
      <html lang=en>
        <meta charset=utf-8>
        <title>%s</title>
        <link rel=stylesheet href="https://manakai.github.io/css/pod.css">
        <meta name=viewport content="width=device-width">

        <h1><a href="%s" rel=top>%s</a></h1>

        %s

        <footer>
          <ul>
          <li><a href="%s" rel=top>Top</a>
          </ul>
        </footer>
    },
        $title,
        $to_repo_url->($root_url, ""),
        $title,
        $node->inner_html,
        $to_repo_url->($root_url, "");
  };
  
  pod2html $pod_path->slurp_utf8 => $html_path, $write,
      to_repo_url => $to_repo_url,
      to_module_url => $to_module_url,
      module_name => $module_name,
      repo => undef,
      source_path => undef;
} # main

our $NoRun;
main (@ARGV) unless $NoRun;

=head1 LICENSE

Copyright 2014-2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
