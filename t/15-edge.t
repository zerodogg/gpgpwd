#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use File::Temp qw(tempdir);
use File::Copy qw(move);
use IPC::Open3;
use FindBin;
use lib $FindBin::Bin;
use TestLib;

use Test::More tests => 1;

# Create a dummy gpg binary
my $tmpdir = tempdir('gpgpwd-testpath-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);
open(my $o,'>',$tmpdir.'/gpg');
print {$o} "#!/usr/bin/perl\n";
print {$o} 'if(@ARGV && grep(/--version/,@ARGV)) { print "1.1.1\n"; }'."\n";
print {$o} "exit(0);\n";
close($o);
chmod(0700,$tmpdir.'/gpg');
symlink($tmpdir.'/gpg',$tmpdir.'/gpg2');

$ENV{PATH} = $tmpdir.':'.$ENV{PATH};

eSpawn(qw(--debuginfo));
t_expect('-re','.*flags\s*:.*useGPGv2.*','Should use gpgv2 even if gpgv1 is available');
