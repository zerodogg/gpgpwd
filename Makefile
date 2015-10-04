# gpgpwd makefile

VERSION=$(shell ./gpgpwd --version|perl -p -e 's/^\D+//; chomp')

ifndef prefix
# This little trick ensures that make install will succeed both for a local
# user and for root. It will also succeed for distro installs as long as
# prefix is set by the builder.
prefix=$(shell perl -e 'if($$< == 0 or $$> == 0) { print "/usr" } else { print "$$ENV{HOME}/.local"}')

# Some additional magic here, what it does is set BINDIR to ~/bin IF we're not
# root AND ~/bin exists, if either of these checks fail, then it falls back to
# the standard $(prefix)/bin. This is also inside ifndef prefix, so if a
# prefix is supplied (for instance meaning this is a packaging), we won't run
# this at all
BINDIR ?= $(shell perl -e 'if(($$< > 0 && $$> > 0) and -e "$$ENV{HOME}/bin") { print "$$ENV{HOME}/bin";exit; } else { print "$(prefix)/bin"}')
endif

BINDIR ?= $(prefix)/bin
DATADIR ?= $(prefix)/share

CORE_DISTFILES = COPYING INSTALL Makefile NEWS README.md gpgpwd.1 t
DISTFILES = $(CORE_DISTFILES) gpgpwd

# Install gpgpwd
install:
	mkdir -p "$(BINDIR)"
	cp gpgpwd "$(BINDIR)"
	chmod 755 "$(BINDIR)/gpgpwd"
	[ -e gpgpwd.1 ] && mkdir -p "$(DATADIR)/man/man1" && cp gpgpwd.1 "$(DATADIR)/man/man1" || true
localinstall:
	mkdir -p "$(BINDIR)"
	ln -sf $(shell pwd)/gpgpwd $(BINDIR)/
	[ -e gpgpwd.1 ] && mkdir -p "$(DATADIR)/man/man1" && ln -sf $(shell pwd)/gpgpwd.1 "$(DATADIR)/man/man1" || true
# Uninstall an installed gpgpwd
uninstall:
	rm -f "$(BINDIR)/gpgpwd" "$(BINDIR)/gpconf" "$(DATADIR)/man/man1/gpgpwd.1"
	rm -rf "$(DATADIR)/gpgpwd"
# Clean up the tree
clean:
	rm -f `find|egrep '~$$'`
	rm -f gpgpwd-*.tar.bz2 gpgpwd-*.tar.bz2.sig
	rm -rf gpgpwd-$(VERSION)
	rm -rf gpgpwd-fat-$(VERSION)
	rm -f gpgpwd.1 gpgpwd.fat
	rm -rf fat-local fatlib
# Verify syntax
sanity:
	@perl -c gpgpwd
# Create a manpage from the POD
man:
	pod2man --name "gpgpwd" --center "" --release "gpgpwd $(VERSION)" ./gpgpwd ./gpgpwd.1
# Create the tarball
distrib: clean test man
	mkdir -p gpgpwd-$(VERSION)
	cp -r $(DISTFILES) ./gpgpwd-$(VERSION)
	tar -jcvf gpgpwd-$(VERSION).tar.bz2 ./gpgpwd-$(VERSION)
	rm -rf gpgpwd-$(VERSION)
	rm -rf gpgpwd-fat-$(VERSION) 
	rm -f gpgpwd.1
	gpg --sign --detach-sign gpgpwd-$(VERSION).tar.bz2
# Create a fat gpgpwd
fat: buildfat testfat
buildfat: 
	cpanm -L fat-local Try::Tiny Term::ReadLine Term::ReadLine::Perl5 JSON::PP JSON App::FatPacker --notest
	PERL5LIB="$(shell pwd)/fat-local/lib/perl5" PERL_RL="Perl" ./fat-local/bin/fatpack pack gpgpwd > gpgpwd.fat
	chmod +x gpgpwd.fat
testfat:
	perl -c gpgpwd.fat
	GPGPWD_TEST_BINNAME="gpgpwd.fat" make test
fatdistrib: clean test man fat
	mkdir -p gpgpwd-fat-$(VERSION)
	cp -r $(DISTFILES) ./gpgpwd-fat-$(VERSION)
	cp gpgpwd.fat gpgpwd-fat-$(VERSION)
	tar -jcvf gpgpwd-fat-$(VERSION).tar.bz2 ./gpgpwd-fat-$(VERSION)
	gpg --sign --detach-sign gpgpwd-fat-$(VERSION).tar.bz2
	rm -rf fat-local fatlib
	rm -f gpgpwd.fat gpgpwd.1
# Run tests
test: sanity
	@perl '-e' 'eval("use Expect;1") or die("Requires the Expect module to be installed\n")'
	@perl '-MExtUtils::Command::MM' '-e' 'test_harness(0,undef,undef)' t/*.t
