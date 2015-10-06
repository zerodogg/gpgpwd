#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 16;
use File::Temp qw(tempdir);
use FindBin;
use lib $FindBin::Bin;
use TestLib;


enable_raw_gpgpwd();

my $tmpdir = tempdir('gpgpwd-gnupghome-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);
my $gnupgPref = $ENV{GNUPGHOME};
$ENV{GNUPGHOME} = $tmpdir;
eSpawn('config');
t_expect('Error: You appear to have no GnuPG-keys, which gpgpwd uses for its','Should display gpg --gen-key info');
t_exitvalue('nonzero','Should error out');
$ENV{GNUPGHOME} = $gnupgPref;

eSpawn('get');
t_expect('Missing parameter to get: what to retrieve','Should display that a param to get is missing');
t_exitvalue('nonzero','Should error out');

eSpawn('set');
t_expect('Missing parameter to set: what to set','Should display that a param to set is missing');
t_exitvalue('nonzero','Should error out');

eSpawn('remove');
t_expect('Missing parameter to remove: what to remove','Should display that a param to remove is missing');
t_exitvalue('nonzero','Should error out');

eSpawn('rename');
t_expect('Missing parameters to rename: old name, new name','Should display that both params to rename is missing');
t_exitvalue('nonzero','Should error out');

eSpawn('rename','x');
t_expect('Missing parameters to rename: new name','Should display that a param to rename is missing');
t_exitvalue('nonzero','Should error out');

eSpawn('batchadd');
t_expect('Missing parameter to batchadd: path to the file to read','Should display that a param to batchadd is missing');
t_exitvalue('nonzero','Should error out');

eSpawn('git');
t_expect('Missing parameter: which git command to run','Should display that a param to git is missing');
t_exitvalue('nonzero','Should error out');
