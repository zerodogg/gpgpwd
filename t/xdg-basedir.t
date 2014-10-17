#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 2;
use File::Temp qw(tempdir);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my $tmpdir = tempdir('gpgpwdt-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);

$ENV{XDG_CONFIG_HOME} = $tmpdir;

enable_raw_gpgpwd();

system(getCmd('config'));

ok(-d $tmpdir.'/gpgpwd','The config directory was created');
ok(-e $tmpdir.'/gpgpwd/gpgpwd.conf','The config file was created');
