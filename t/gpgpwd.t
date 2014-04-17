#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::Simple tests => 22;
use File::Temp qw(tempfile);
use Cwd qw(realpath);
use File::Basename qw(dirname);
use Expect;

my $e;
my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);

eSpawn(qw(add testpassword));
t_expect('Enter the password you want to use, or press enter to use the random','Password information #1');
t_expect('password listed below. Some commands are available, enter /help to list them','Password information #2');
t_expect('-re','Random password: .*','Random password');
t_expect('Password> ','Password prompt');
$e->send("1234567890\n");

t_wait_eof();
ok(-e $testfile,'The file exists');

eSpawn(qw(get testpassword));
t_expect('testpassword        : 1234567890','Retrieve password');

eSpawn(qw(get testpwd));
t_expect('testpassword        : 1234567890','Retrieve password with typos');

eSpawn(qw(add testpassword));
t_expect('An entry for testpassword already exists, with the password: 1234567890','Existing password');
t_expect('Enter the password you want to change it to, or press enter to use the random','Password information #1');
t_expect('password listed below. Some commands are available, enter /help to list them','Password information #2');
t_expect('-re','Random password: .*','Random password');
t_expect('Password> ','Password prompt');
$e->send("abcdefghij\n");
t_expect('Changed testpassword from 1234567890 to abcdefghij','Password change');

eSpawn(qw(add tsting));
t_expect('Enter the password you want to use, or press enter to use the random','Password information #1');
t_expect('password listed below. Some commands are available, enter /help to list them','Password information #2');
t_expect('-re','Random password: .*','Random password');
t_expect('Password> ','Password prompt');
$e->send("qwertyuio\n");

eSpawn(qw(get tist));
t_expect('tsting              : qwertyuio','Retrieve password fuzzy');

eSpawn(qw(get testingpwd));
t_expect('tsting              : qwertyuio','Retrieve password with typos');

eSpawn(qw(get testingpassword));
t_expect('testpassword        : abcdefghij','Retrieve password with too many letters');

eSpawn(qw(rename testpassword renamed));
t_expect('Renamed the entry for testpassword to renamed','Renaming entry');

eSpawn(qw(get testpassword));
t_expect('(no passwords found for "testpassword")','Fail to retrieve the renamed password');

t_wait_eof();
unlink($testfile);

sub t_wait_eof
{
    $e->expect(10,undef);
    $e = undef;
}

sub t_expect
{
    ok($e->expect(4,$_[0]),$_[1]);
}

sub eSpawn
{
    if(defined $e)
    {
        t_wait_eof();
    }
    $e = Expect->spawn(getCmd(@_));
    if (!@ARGV || $ARGV[0] ne '-v')
    {
        $e->log_stdout(0);
    }
    return $e;
}

sub getCmd
{
    state $dir = dirname(realpath($0));
    return ($dir.'/../gpgpwd','--no-git','--password-file',$testfile,@_);
}
