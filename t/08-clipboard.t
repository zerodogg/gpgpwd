#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 6;
use File::Temp qw(tempfile);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

SKIP:
{
    if (!defined $ENV{DISPLAY} || !length($ENV{DISPLAY}))
    {
        $ENV{GPGPWD_TEST_NO_IMPORTANT_SKIP} && die('No $DISPLAY, can not complete tests');
        skip('No $DISPLAY',5);
    }
    if (!InPath('xclip'))
    {
        $ENV{GPGPWD_TEST_NO_IMPORTANT_SKIP} && die('xclip not installed, can not complete tests');
        skip('xclip is not installed',5);
    }
    eSpawn(qw(add testpassword));
    t_expect('Password> ','Password prompt');
    expect_send("1234567890\n");
    t_expect('Username> ','Username prompt');
    expect_send("user\n");
    t_exitvalue(0,'Adding should succeed');

    eSpawn(qw(get testpassword));
    t_expect('testpassword        : 1234567890 (copied)','Retrieve password (copied)');
    t_exitvalue(0,'Retrieval should succeed');

    # Expect seems to kill off the xclip instance, so we start a new gpgpwd
    # instance directly with system() here
    open(my $SAVED_STDOUT, '>&',\*STDOUT);
    open(my $SAVED_STDERR, '>&',\*STDOUT);
    open(STDOUT,'>','/dev/null');
    open(STDERR,'>','/dev/null');
    system(getCmd('get','testpassword'));
    open(STDOUT,'>&',$SAVED_STDOUT);
    open(STDERR,'>&',$SAVED_STDERR);
    open(my $in,'-|',qw(xclip -out -selection clipboard));
    my $val = <$in>;
    close($in);
    is($val,'1234567890','Clipboard should contain the password');
};

unlink($testfile);
