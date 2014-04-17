# gpgpwd makefile

VERSION=$(shell ./gpgpwd --version|perl -pi -e 's/^\D+//; chomp')

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

DISTFILES = COPYING gpgpwd INSTALL Makefile NEWS README.md gpgpwd.1

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
	rm -f gpgpwd-*.tar.bz2
	rm -rf gpgpwd-$(VERSION)
	rm -f gpgpwd.1
# Verify syntax
sanity:
	@perl -c gpgpwd
# Create a manpage from the POD
man:
	pod2man --name "gpgpwd" --center "" --release "gpgpwd $(VERSION)" ./gpgpwd ./gpgpwd.1
# Create the tarball
distrib: clean test man
	mkdir -p gpgpwd-$(VERSION)
	cp $(DISTFILES) ./gpgpwd-$(VERSION)
	tar -jcvf gpgpwd-$(VERSION).tar.bz2 ./gpgpwd-$(VERSION)
	rm -rf gpgpwd-$(VERSION)
	rm -f gpgpwd.1
# Run tests
test: sanity
	perl t/gpgpwd.t
