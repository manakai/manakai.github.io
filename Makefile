all: generate-docs

generate-docs:
	curl http://wakaba.github.io/packages/pmbp | sh
	perl local/bin/pmbp.pl \
	    --install-module Path::Tiny \
	    --install-module Exporter::Lite \
	    --install-module Pod::Simple~3.28 \
	    --create-perl-command-shortcut perl
	./perl _generate_perldocs.pl
