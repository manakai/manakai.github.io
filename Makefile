all: generate-docs

deps:
	curl http://wakaba.github.io/packages/pmbp | sh
	perl local/bin/pmbp.pl \
	    --install-module Path::Tiny \
	    --install-module Exporter::Lite \
	    --install-module Pod::Simple~3.28 \
	    --create-perl-command-shortcut perl

generate-docs: deps
	./perl _generate_perldocs.pl

updatenightly: generate-docs
	git add pod
	git add --update pod

test:
	ls pod/index.html > /dev/null && \
	ls pod/Web/DOM/Document.html > /dev/null && \
	ls pod/webhacc.html > /dev/null
