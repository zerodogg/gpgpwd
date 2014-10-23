#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 8;
use File::Temp qw(tempfile);
use IPC::Open2 qw(open2);
use MIME::Base64 qw(encode_base64);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 2);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

# Write a valid v2 file
# Silence gpg
{
    my $childOut;
    my $o;
    my $stderr;
    open($stderr, '>&',\*STDERR);
    open(STDERR,'>','/dev/null');

    open2($childOut, $o,qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --no-tty --encrypt));
    print {$o} 'testpassword';
    close($o);
    local $/ = undef;
    my $encPW = <$childOut>;
    close($childOut);
    $encPW = encode_base64($encPW);
    chomp($encPW);

    open2($childOut, $o,qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --no-tty --clearsign));
    print {$o} '{ "pwds":{"testpw":"'.$encPW.'"}, "gpgpwdDataVersion":2 }'."\n";
    close($o);
    local $/ = undef;
    my $data = <$childOut>;
    close($childOut);

    open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --no-tty --encrypt --output),$testfile);
    print {$o} $data;
    close($o);

    open(STDERR,'>&',$stderr);
}
# Restore stderr

eSpawn(qw(--set clipboardMode=disable get testpw));
t_expect('Database upgrade triggered...','Initial upgrade message');
t_expect('Converting ...done','Conversion message');
t_expect('Writing updated data...done','Write message');
t_expect('Verifying integrity...done - upgrade successfully completed','Integrity and upgrade successful');
t_expect('-re','testpw\s*: testpassword'."\r?\$",'Should retrieve database entry');
t_exitvalue(0,'The upgrade should succeed');

eSpawn(qw(--set clipboardMode=disable get testpw));
t_expect('-re','testpw\s*: testpassword'."\r?\$",'Should retrieve database entry');
t_exitvalue(0,'The retrieval should succeed');
unlink($testfile);
