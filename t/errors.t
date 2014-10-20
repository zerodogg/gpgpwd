#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 2;
use File::Temp qw(tempdir);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my $tmpdir = tempdir('gpgpwd-gnupghome-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);
$ENV{GNUPGHOME} = $tmpdir;

enable_raw_gpgpwd();

eSpawn('config');
t_expect('Error: You appear to have no GnuPG-keys, which gpgpwd uses for its');
t_exitvalue('nonzero','Should error out');
