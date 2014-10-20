#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 16;
use File::Temp qw(tempdir);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my $tmpdir = tempdir('gpgpwdt-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);

$ENV{XDG_CONFIG_HOME} = $tmpdir;

enable_raw_gpgpwd();

system(getCmd('config'));

ok(-e $tmpdir.'/gpgpwd/gpgpwd.conf','The config file was created');

eSpawn('config','git');
t_expect('git=auto','Git should be auto by default');
t_exitvalue(0,'Config retrieval should succeed');

eSpawn('config','dataPath');
t_expect('dataPath=DEFAULT','dataPath should be DEFAULT by default');
t_exitvalue(0,'Config retrieval should succeed');

eSpawn('config','clipboardMode');
t_expect('clipboardMode=clipboard','clipboardMode should be clipboard by default');
t_exitvalue(0,'Config retrieval should succeed');

eSpawn('config','clipboardMode=both');
t_exitvalue(0,'Config setting should succeed');

eSpawn('config','clipboardMode');
t_expect('clipboardMode=both','clipboardMode should have been changed');
t_exitvalue(0,'Config retrieval should succeed');

eSpawn('config','git=false');
t_exitvalue(0,'Config setting should succeed');

eSpawn('config','git');
t_expect('git=false','git should have been changed');
t_exitvalue(0,'Config retrieval should succeed');

eSpawn('config','dataPath='.$tmpdir.'/.gpgpwddb');
t_exitvalue(0,'Config setting should succeed');

eSpawn('config','dataPath');
t_expect('dataPath='.$tmpdir.'/.gpgpwddb','dataPath should have been changed');
t_exitvalue(0,'Config retrieval should succeed');
