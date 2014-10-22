#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 14;
use File::Temp qw(tempfile);
use IPC::Open2 qw(open2);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

open(my $o,'>',$testfile);
print {$o} 'garbage';
close($o);
eSpawn(qw(get anothertest));
t_expect('Decryption failed: GPG did not return any data','GPG corruption error');
t_exitvalue('nonzero','Corruption should exit with nonzero');

unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} 'garbage';
close($o);
eSpawn(qw(get anothertest));
t_expect("Failed to decode encrypted JSON data. The file is either not a gpgpwd",'JSON corruption error #1');
t_expect("file, or the file is corrupt.",'JSON corruption error #2');
t_exitvalue('nonzero','Failing to decode should exit with nonzero');

unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} '{ }';
close($o);
eSpawn(qw(get anothertest));
t_expect('-re','Detected possible corruption in \S+ - refusing to continue','Empty JSON data error');
t_exitvalue('nonzero','Empty JSON data error should exit with nonzero');

unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} '{ "pwds":{}, "gpgpwdDataVersion":2 }';
close($o);
eSpawn(qw(get anothertest));
t_expect('pre-2 dataformat claiming to be 2+. Someone has modified your password file. Aborting.','Unsigned v2 data');
t_exitvalue('nonzero','Unsigned v2 data error should exit with nonzero');

unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA1\n\n";
print {$o} '{ "pwds":{}, "gpgpwdDataVersion":2 }';
print {$o} "\n-----BEGIN PGP SIGNATURE-----\nVersion: GnuPG v2.0.22 (GNU/Linux)\nComment: gpgpwd password file.\n";
print {$o} "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n-----END PGP SIGNATURE-----\n";
close($o);
eSpawn(qw(get anothertest));
t_expect('Signature validation failed: invalid signature','Invalid gpg signature');
t_exitvalue('nonzero','Invalid signature error should exit with nonzero');

unlink($testfile);
# Silence gpg
my $stderr;
open($stderr, '>&',\*STDERR);
open(STDERR,'>','/dev/null');
open2(my $out, $o,qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --no-tty --clearsign));
print {$o} '{ "pwds":{"testpw":"f2ca1bb6c7e907d06dafe4687e579fce76b37e4e93b7605022da52e6ccc26fd2"}, "gpgpwdDataVersion":2 }'."\n";
close($o);
{
    local $/ = undef;
    my $data = <$out>;
    close($out);
    open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --no-tty --encrypt --output),$testfile);
    print {$o} $data;
    close($o);
}
# Restore stderr
open(STDERR,'>&',$stderr);

eSpawn(qw(get testpw));
t_expect('Fatal error: Failed to decrypt password for "testpw".','Fatal decryption error');
t_expect('This indicates either a partial corruption of the password database, or','Friendly explanation of the error');
t_exitvalue('nonzero','Invalid signature error should exit with nonzero');


unlink($testfile);
