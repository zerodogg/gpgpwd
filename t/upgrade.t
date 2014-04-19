#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 3;
use File::Temp qw(tempfile);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

open(my $o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} '{ "pwds":{"mytestpassword":"gpgpwd"}, "gpgpwdDataVersion":1, "generator":"test", "lastVersion":"0.4" }';
close($o);
eSpawn(qw(get mytestpassword));
t_expect('Your database file is using the old v1 format. It needs to be upgraded.','Upgrade message');

t_wait_eof();
eSpawn(qw(upgrade));
t_expect('upgrade successfully completed','Upgrade completion');

t_wait_eof();
eSpawn(qw(get mytestpassword));
t_expect('mytestpassword      : gpgpwd','Retrieve password');

t_wait_eof();
unlink($testfile);
