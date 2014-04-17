#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 33;
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
t_expect('Enter the password you want to change it to, or press enter to use the random','Changing password information #1');
t_expect('password listed below. Some commands are available, enter /help to list them','Changing password information #2');
t_expect('-re','Random password: .*','Random password');
t_expect('Password> ','Password prompt for existing password');
$e->send("abcdefghij\n");
t_expect('Changed testpassword from 1234567890 to abcdefghij','Password change');

eSpawn(qw(add tsting));
t_expect('Password> ','Password prompt for second password entry');
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

eSpawn(qw(add anothertest));
t_expect('Password> ','Password prompt before help');
$e->send("/help\n");
t_expect('The following commands are available','Help output');
t_expect('Password> ','A new password prompt after /help');
$e->send("/regenerate\n");
t_expect('-re','Random password: \S{15}','Regenerated password');
t_expect('Password> ','A new password prompt after /regenerate');
$e->send("/alphanumeric\n");
t_expect('-re','Random password: \w{15}','Alphanumeric-only password');
t_expect('Password> ','A new password prompt after /alphanumeric');
$e->send("\n");
t_expect('-re','^Using password: \S{15}','Using information');

t_wait_eof();
open(my $o,'>',$testfile);
print {$o} 'garbage';
close($o);
eSpawn(qw(get anothertest));
t_expect('Decryption failed: GPG did not return any data','GPG corruption error');

t_wait_eof();
unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} 'garbage';
close($o);
eSpawn(qw(get anothertest));
t_expect("Failed to decode encrypted JSON data. The file is either not a gpgpwd",'JSON corruption error #1');
t_expect("file, or the file is corrupt.",'JSON corruption error #2');

t_wait_eof();
unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} '{ }';
close($o);
eSpawn(qw(get anothertest));
t_expect('-re','Detected possible corruption in \S+ - refusing to continue','Empty JSON data error');

t_wait_eof();
unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} '{ "pwds":{}, "gpgpwdDataVersion":2 }';
close($o);
eSpawn(qw(get anothertest));
t_expect('pre-2 dataformat claiming to be 2+. Someone has modified your password file. Aborting.','Unsigned v2 data');

t_wait_eof();
unlink($testfile);
open($o,'|-',qw(gpg --gnupg --default-recipient-self --no-verbose --quiet --personal-compress-preferences uncompressed --encrypt --output),$testfile);
print {$o} "-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA1\n\n";
print {$o} '{ "pwds":{}, "gpgpwdDataVersion":2 }';
print {$o} "\n-----BEGIN PGP SIGNATURE-----\nVersion: GnuPG v2.0.22 (GNU/Linux)\nComment: gpgpwd password file.\n";
print {$o} "\nXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX\n-----END PGP SIGNATURE-----\n";
close($o);
eSpawn(qw(get anothertest));
t_expect('Signature validation failed: invalid signature','Invalid gpg signature');

t_wait_eof();
unlink($testfile);

sub t_wait_eof
{
    $e->expect(10,undef);
    $e = undef;
}

sub t_expect
{
    my @tests;
    push(@tests,shift);
    if ($tests[0] =~ /^-/)
    {
        push(@tests,shift);
    }
    my $name = shift;
    my $match = $e->expect(4,@tests);
    if ($match)
    {
        ok(1,$name);
    }
    else
    {
        is($e->before,$tests[-1],$name);
    }
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
