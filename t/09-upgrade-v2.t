#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 19;
use File::Temp qw(tempfile);
use File::Copy qw(copy);
use File::Path qw(mkpath);
use IPC::Open2 qw(open2);
use Cwd qw(cwd);
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

# HOME is pointing to a temporary directory at this point
my $t = $ENV{HOME};

mkpath($t.'/t1');
copy($testfile,$t.'/t1/gpgpwd.db');

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

enable_raw_gpgpwd();
my $oldDir = cwd;
chdir($t.'/t1');
system(qw(git init --quiet));
system(qw(git add .));
system(qw(git commit -m commit --quiet));

eSpawn(qw(git clone),$t.'/t1/');
t_expect('-re','Git repository initialized in.*','Success message');
t_exitvalue(0,'git clone should succeed');

eSpawn(qw(-p),$t.'/t1/gpgpwd.db',qw(--set clipboardMode=disable get testpw));
t_expect('Database upgrade triggered...','Initial upgrade message');
t_expect('Converting ...done','Conversion message');
t_expect('Writing updated data...','Write message (partial)');
t_expect('Verifying integrity...done - upgrade successfully completed','Integrity and upgrade successful');
t_expect('-re','testpw\s*: testpassword'."\r?\$",'Should retrieve database entry');
t_exitvalue(0,'The upgrade should succeed');

eSpawn(qw(--set clipboardMode=disable get testpw));
t_expect('Database upgrade triggered...','Initial upgrade message');
t_expect('-re','testpw\s*: testpassword'."\r?\$",'Should retrieve database entry');
t_exitvalue(0,'The upgrade should succeed');

chdir('/');
