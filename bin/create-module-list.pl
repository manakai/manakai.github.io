use strict;
use warnings;
use Path::Tiny;

my $RootPath = path (__FILE__)->parent->parent->absolute;
my $repos_path = $RootPath->child ('local/repos');

require "_load_pod2html.pl" or die $@;
{
  require Web::DOM::Document;
  my $doc = new Web::DOM::Document;
  $doc->manakai_is_html (1);
  $doc->inner_html (q{
    <!DOCTYPE HTML>
    <p a="b">xya<!----><svg><![CDATA[]]><?x?></svg><template>a</template>
  });
  scalar $doc->child_nodes;
  scalar $doc->get_elements_by_tag_name ('*');
  scalar $doc->inner_html;
}

my $pattern = join '|', map { "\Q$_\E" }
    $RootPath->child ('lib'),
    (glob $RootPath->child ('modules/*/lib')),
    (glob $RootPath->child ('local/perl-*/pm/lib/perl5')),
    (glob $repos_path->child ('*/*/lib'));

my $dest = q{local/fatlib};
print qq{#!/bin/bash\x0A};
print qq{set -eo pipefail\x0A};
my $dirs = {};
my $cp_files = join "", sort { $a cmp $b } map {
  my $abs_path = $_;
  my $rel_path = $abs_path;
  $rel_path =~ s{^(?:$pattern)/}{};
  my $dir = $rel_path;
  $dir =~ s{[^/]*$}{};
  $dirs->{$dir} = 1;
  "cp \Q$abs_path\E \Q$dest/$rel_path\E\x0A";
} grep { m{^(?:$pattern)/} } values %INC;
delete $dirs->{''};
print join '', map { "mkdir -p \Q$dest/$_\E\x0A" } sort { $a cmp $b } keys %$dirs;
print $cp_files;

=head1 LICENSE

Copyright 2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
