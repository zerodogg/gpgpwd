#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 6;
use File::Temp qw(tempdir);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my $tmpdir = tempdir('gpgpwdt-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);

$ENV{XDG_CONFIG_HOME} = $tmpdir;

enable_raw_gpgpwd();

open(my $o,'>',$tmpdir.'/pwdbatch');
print {$o} "# A comment\n";
print {$o} "test 1234567890\n";
print {$o} "\n\n";
print {$o} "abc zxy\n";
print {$o} "#another comment\n";
close($o);

eSpawn(qw(batchadd),$tmpdir.'/pwdbatch');
t_expect('Read 2 entries from '.$tmpdir.'/pwdbatch','Confirmation message');
t_exitvalue(0,'Adding should succeed');

eSpawn(qw(get abc));
t_expect('abc                 : zxy','Retrieve zxy password');
t_exitvalue(0,'Retrieval should succeed');

eSpawn(qw(get test));
t_expect('test                : 1234567890','Retrieve test password');
t_exitvalue(0,'Retrieval should succeed');
