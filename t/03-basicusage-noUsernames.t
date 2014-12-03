#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 42;
use File::Temp qw(tempfile);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

eSpawn(qw(config storeUsernames=false));
t_exitvalue(0,'Setting storeUsernames to false should succeed');

eSpawn(qw(add testpassword));
t_expect('Enter the password you want to use, or press enter to use the random','Password information #1');
t_expect('password listed below. Some commands are available, enter /help to list them','Password information #2');
t_expect('-re','Random password: .*','Random password');
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_exitvalue(0,'Adding should succeed');

ok(-e $testfile,'The file exists');

eSpawn(qw(get testpassword));
t_expect('testpassword        : 1234567890','Retrieve password');
t_exitvalue(0,'Retrieval should succeed');

eSpawn(qw(get testpwd));
t_expect('testpassword        : 1234567890','Retrieve password with typos');
t_exitvalue(0,'Retrieval with typos should succeed');

eSpawn(qw(add testpassword));
t_expect('An entry for testpassword already exists, with the password: 1234567890','Existing password');
t_expect('Enter the password you want to change it to, or press enter to use the random','Changing password information #1');
t_expect('password listed below. Some commands are available, enter /help to list them','Changing password information #2');
t_expect('-re','Random password: .*','Random password');
t_expect('Password> ','Password prompt for existing password');
expect_send("abcdefghij\n");
t_expect('Changed testpassword from 1234567890 to abcdefghij','Password change');
t_exitvalue(0,'Changing a password should succeed');

eSpawn(qw(add tsting));
t_expect('Password> ','Password prompt for second password entry');
expect_send("qwertyuio\n");
t_exitvalue(0,'Adding a second password should succeed');

eSpawn(qw(get tist));
t_expect('tsting              : qwertyuio','Retrieve password fuzzy');
t_exitvalue(0,'Getting a fuzzy password should succeed');

eSpawn(qw(get testingpwd));
t_expect('tsting              : qwertyuio','Retrieve password with typos');
t_exitvalue(0,'Getting a password with typos should succeed');

eSpawn(qw(get testingpassword));
t_expect('testpassword        : abcdefghij','Retrieve password with too many letters');
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
t_exitvalue(0,'Adding a new password should succeed');

eSpawn(qw(-s clipboardMode=disabled -s defaultPasswordLength=20 add testpword));
t_expect('-re',"Random password: .....................\n",'Random password should be 20 characters');
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_exitvalue(0,'Adding should succeed');


unlink($testfile);
