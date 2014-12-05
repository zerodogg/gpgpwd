#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 80;
use File::Temp qw(tempfile);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

eSpawn(qw(add testpassword));
t_expect('Adding an entry for testpassword','Adding message');
t_expect('-re','Random password: .*','Random password');
t_expect('  Enter /help for help.','Help message');
t_expect('  Enter a password to use a custom password.','Custom password message');
t_expect('  Just press enter to use the random password.','Random password entry');
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('  Enter a username for this entry.','Username message');
t_expect('  Just press enter to not store any username.','No username message');
t_expect('Username> ','Username prompt');
expect_send("username\n");
t_exitvalue(0,'Adding should succeed');

ok(-e $testfile,'The file exists');

eSpawn(qw(get testpassword));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?username','Retrieve entry');
t_exitvalue(0,'Retrieval should succeed');

eSpawn(qw(get testpwd));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?username','Retrieve entry with typos');
t_exitvalue(0,'Retrieval with typos should succeed');

eSpawn(qw(add testpassword));
t_expect('Changing the entry for testpassword','Adding message');
t_expect('-re','Random password: \S*','Random password');
t_expect('  Enter /help for help.','Help message');
t_expect('-re','  Enter - to keep the previously stored password \(\S*\)\.','Previous password message');
t_expect('  Enter your new password to add a new custom password.','Custom password message');
t_expect('  Just press enter to use the random password.','Random password entry');
t_expect('Password> ','Password prompt for existing password');
expect_send("abcdefghij\n");
t_expect('  Enter a new username for this entry.','New username message');
t_expect('  Just press enter to keep the current username (username).','Keep username message');
t_expect('  Enter a single dot (".") to remove the stored username.','Remove username message');
t_expect('Username> ','Username prompt');
expect_send("newusername\n");
t_expect('Changed testpassword from 1234567890 to abcdefghij','Password change');
t_exitvalue(0,'Changing a password should succeed');

eSpawn(qw(add tsting));
t_expect('Password> ','Password prompt for second entry');
expect_send("qwertyuio\n");
t_expect('Username> ','Username prompt for second entry');
expect_send("seconduname\n");
t_exitvalue(0,'Adding a second password should succeed');

eSpawn(qw(get tist));
t_expect('-re','tsting              : qwertyuio\s+(\S+\s+)?seconduname','Retrieve password fuzzy');
t_exitvalue(0,'Getting a fuzzy password should succeed');

eSpawn(qw(get testingpwd));
t_expect('-re','tsting              : qwertyuio\s+(\S+\s+)?seconduname','Retrieve password with typos');
t_exitvalue(0,'Getting a password with typos should succeed');

eSpawn(qw(get testingpassword));
t_expect('-re','testpassword        : abcdefghij\s+(\S+\s+)?newusername','Retrieve password with too many letters');
t_exitvalue(0,'Getting a password with too many letters should succeed');

eSpawn(qw(rename testpassword renamed));
t_expect('Renamed the entry for testpassword to renamed','Renaming entry');
t_exitvalue(0,'Renaming should succeed');

eSpawn(qw(get testpassword));
t_expect('(no passwords found for "testpassword")','Fail to retrieve the renamed password');
t_exitvalue(0,'Failing to find a match should succeed');

eSpawn(qw(add anothertest));
t_expect('Password> ','Password prompt before help');
expect_send("/help\n");
t_expect('The following commands are available','Help output');
t_expect('Password> ','A new password prompt after /help');
expect_send("/regenerate\n");
t_expect('-re','Random password: \S{15}','Regenerated password');
t_expect('Password> ','A new password prompt after /regenerate');
expect_send("/alphanumeric\n");
t_expect('-re','Random password: \w{15}','Alphanumeric-only password');
t_expect('Password> ','A new password prompt after /alphanumeric');
expect_send("\n");
t_expect('-re','^Using password: \S{15}','Using information');
t_expect('Username> ','Username prompt');
expect_send("username\n");
t_exitvalue(0,'Adding a new password should succeed');

eSpawn(qw(-s clipboardMode=disabled -s defaultPasswordLength=20 add testpword));
t_expect('-re',"Random password: .....................\n",'Random password should be 20 characters');
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('Username> ','Username prompt');
expect_send("username\n");
t_exitvalue(0,'Adding should succeed');

eSpawn(qw(add withoutusername));
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('Username> ','Username prompt');
expect_send("\n");
t_exitvalue(0,'Adding should succeed');

eSpawn(qw(-s clipboardMode=disabled get withoutusername));
t_expect('-re','withoutusername     : 1234567890'."\r?\$",'Should retrieve username-less entry');
t_exitvalue(0,'Getting a username-less entry should succeed');

eSpawn(qw(add changingonlyone));
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('Username> ','Username prompt');
expect_send("theuser\n");
t_exitvalue(0,'Adding should succeed');

eSpawn(qw(-s clipboardMode=disabled get changingonlyone));
t_expect('-re','changingonlyone\s*: 1234567890\s+(\S+\s+)?theuser'."\r?\$",'Should retrieve proper entry with username');
t_exitvalue(0,'Getting a the username entry should succeed');

eSpawn(qw(set changingonlyone));
t_expect('Password> ','Password prompt');
expect_send("-\n");
t_expect('Username> ','Username prompt');
expect_send("newuser\n");
t_exitvalue(0,'Changing should succeed');

eSpawn(qw(-s clipboardMode=disabled get changingonlyone));
t_expect('-re','changingonlyone\s*: 1234567890\s+(\S+\s+)?newuser'."\r?\$",'Should retrieve the new username');
t_exitvalue(0,'Getting a the username entry should succeed');

eSpawn(qw(set changingonlyone));
t_expect('Password> ','Password prompt');
expect_send("newpw\n");
t_expect('Username> ','Username prompt');
expect_send("\n");
t_exitvalue(0,'Changing should succeed');

eSpawn(qw(-s clipboardMode=disabled get changingonlyone));
t_expect('-re','changingonlyone\s*: newpw\s+(\S+\s+)?newuser'."\r?\$",'Should retrieve the new password');
t_exitvalue(0,'Getting a the password entry should succeed');

eSpawn(qw(set changingonlyone));
t_expect('Password> ','Password prompt');
expect_send("-\n");
t_expect('Username> ','Username prompt');
expect_send(".\n");
t_exitvalue(0,'Changing should succeed');

eSpawn(qw(-s clipboardMode=disabled get changingonlyone));
t_expect('-re','changingonlyone\s*: newpw'."\r?\$",'Should retrieve the entry with no username');
t_exitvalue(0,'Getting a the password entry should succeed');

unlink($testfile);
