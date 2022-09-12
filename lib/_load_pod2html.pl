use strict;
use warnings;
use Path::Tiny;

my $RootPath = path (__FILE__)->parent->parent->absolute;

my $repos_path = $RootPath->child ('local/repos');
{
  unshift our @INC,
      $repos_path->child ('wakaba/perl-charclass/lib')->stringify,
      $repos_path->child ('manakai/perl-web-dom/lib')->stringify,
      $repos_path->child ('manakai/perl-web-markup/lib')->stringify,
      $repos_path->child ('manakai/perl-web-encodings/lib')->stringify;
  our $NoRun = 1;
  eval qq{ require "$RootPath/_pod2html.pl" } or die $@;
}

1;

=head1 LICENSE

Copyright 2014-2022 Wakaba <wakaba@suikawiki.org>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
