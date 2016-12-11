#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use File::Temp qw(tempdir tempfile);
use File::Copy qw(move);
use File::Path qw(mkpath);
use IPC::Open3;
use FindBin;
use lib $FindBin::Bin;
use TestLib;

use Test::More tests => 9;

# --
# Test to make sure we use gpg v2 even if gpg v1 is available
# --
# Create a dummy gpg binary
my $tmpdir = tempdir('gpgpwd-testpath-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);
open(my $o,'>',$tmpdir.'/gpg');
print {$o} "#!/usr/bin/perl\n";
print {$o} 'if(@ARGV && grep(/--version/,@ARGV)) { print "1.1.1\n"; }'."\n";
print {$o} "exit(0);\n";
close($o);
chmod(0700,$tmpdir.'/gpg');
symlink($tmpdir.'/gpg',$tmpdir.'/gpg2');

my $PATH = $ENV{PATH};
$ENV{PATH} = $tmpdir.':'.$ENV{PATH};

eSpawn(qw(--debuginfo));
t_expect('-re','.*flags\s*:.*useGPGv2.*','Should use gpgv2 even if gpgv1 is available');
$ENV{PATH} = $PATH;

# --
# Test to make sure we encrypt and sign using the same key we decrypted with
# --
SKIP:
{
    if(!$ENV{GPGPWD_TESTRUNNER_ACTIVE} || $ENV{GPGPWD_TESTRUNNER_ACTIVE} ne '1')
    {
        skip('Requires the testrunner to not mess up the user env',8);
    }
    $PATH = $ENV{PATH};

    my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
    close($th);
    unlink($testfile);
    set_gpgpwd_database_path($testfile);
    # First, initialize gpgpwd with some data
    eSpawn(qw(add testpword));
    t_expect('Password> ','Password prompt');
    expect_send("1234567890\n");
    t_expect('Username> ','Username prompt');
    expect_send("username\n");
    t_exitvalue(0,'Adding should succeed');

    $tmpdir = tempdir('gpgpwd-testpath-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);
    my $realGPG;
    foreach my $pE (split(/:/,$ENV{PATH}))
    {
        if (-x $pE.'/gpg2')
        {
            $realGPG = $pE.'/gpg2';
            last;
        }
    }
    open(my $b,'>',$tmpdir.'/gpg2');
    print {$b} '#!/bin/bash
    exec "'.$realGPG.'" "--default-key" "4EB3AF5718E212424F88FF0D6A8404BC0AD27A93" "$@"';
    close($b);
    chmod(0700,$tmpdir.'/gpg2');

    $ENV{PATH} = $tmpdir.':'.$ENV{PATH};

    open(my $g,'>',$tmpdir.'/gpgkey');
    print {$g} '-----BEGIN PGP PRIVATE KEY BLOCK-----

    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
    Y4Ux9IyNNkP3OA==
    =DONx
    -----END PGP PRIVATE KEY BLOCK-----';
    # Import the new private key
    system(qw(gpg --quiet --import),$tmpdir.'/gpgkey');

    # Then, add some new data
    eSpawn(qw(add testpword2));
    t_expect('Password> ','Password prompt');
    expect_send("1234567890\n");
    t_expect('Username> ','Username prompt');
    expect_send("username\n");
    t_exitvalue(0,'Adding should succeed');

    system(qw(gpg2 --batch --yes --delete-secret-and-public-key 4EB3AF5718E212424F88FF0D6A8404BC0AD27A93));

    # Finally, retrieve said data
    eSpawn(qw(get testpwd));
    t_expect('-re','testpword2\s+:\s+1234567890\s+(\S+\s+)?username','Should be able to retrieve the key without the second gpg key available');
    t_exitvalue(0,'Retrieval should succeed');

    $ENV{PATH} = $PATH;
}
