CURL = curl

all: build generate-docs

PERL = ./perl
P2H = ./p2h

updatenightly: build generate-docs
	git add pod $(P2H)
	git add --update pod
	$(CURL) -sSLf https://raw.githubusercontent.com/wakaba/ciconfig/master/ciconfig | RUN_GIT=1 REMOVE_UNUSED=1 perl

PMBP_OPTIONS =

deps:
	curl https://wakaba.github.io/packages/pmbp | sh
	perl local/bin/pmbp.pl $(PMBP_OPTIONS) \
	    --install-module Path::Tiny \
	    --install-module Exporter::Lite \
	    --install-module Pod::Simple~3.28 \
	    --create-perl-command-shortcut perl

generate-docs: deps
	$(PERL) _generate_perldocs.pl

build: build-p2h

build-p2h: deps-fatpack $(P2H)

deps-fatpack:
	$(PERL) local/bin/pmbp.pl $(PMBP_OPTIONS) \
	    --install-module App::FatPacker \
	    --create-perl-command-shortcut @local/fatpack=fatpack

## For modules that have .packlist
local/fatpacker.trace: _pod2html.pl lib/_load_pod2html.pl \
    lib/_pod2html_common.pl
	#local/fatpack trace --to=$@ _pod2html.pl
	local/fatpack trace --to=$@ lib/_load_pod2html.pl
## For the other modules
local/module-list.sh: bin/create-module-list.pl \
    _pod2html.pl lib/_load_pod2html.pl lib/_pod2html_common.pl
	$(PERL) $< > $@
local/fatpacker.packlists: local/fatpacker.trace
	local/fatpack packlists-for `cat $<` > $@

PERL_ARCHNAME = $(shell $(PERL) -MConfig -e 'print $$Config{archname}')

local/fatlib-files: local/fatpacker.packlists local/module-list.sh
	cd local && ./fatpack tree `cat ../local/fatpacker.packlists`
	bash local/module-list.sh
	#cp -a local/fatlib/$(PERL_ARCHNAME)/* local/fatlib/
	rm -fr local/fatlib/$(PERL_ARCHNAME)
	rm -fr local/fatlib/_load_pod2html.pl
	mv local/fatlib/_pod2html_common.pl local/fatlib/_pod2html_common.pm
	ls -R local/fatlib

$(P2H): _pod2html.pl lib/_pod2html_common.pl local/fatlib-files
	echo '#!/usr/bin/env perl' > local/$@
	cd local && ./fatpack file ../$< >> ../local/$@
	cat local/$@ | sed -e s%"_pod2html_common.pm"%"_pod2html_common.pl"% \
	    > $@
	-git diff $@ | cat
	perl -c $@
	chmod u+x $@

## ------ Tests ------

test: test-deps test-main

test-deps:
test-main: test-main-p2h
	ls pod/index.html > /dev/null && \
	ls pod/Web/DOM/Document.html > /dev/null && \
	ls pod/webhacc.html > /dev/null

test-main-p2h: build-p2h
	$(P2H) "DOM" \
	    local/repos/manakai/perl-web-dom/lib/Web/DOM/Document.pod \
	    > local/test1.html

## License: Public Domain.
