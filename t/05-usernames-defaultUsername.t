#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 56;
use File::Temp qw(tempfile);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

my ($th,$testfile) = tempfile('gpgpwdt-XXXXXXXX',TMPDIR => 1);
close($th);
unlink($testfile);
set_gpgpwd_database_path($testfile);

eSpawn(qw(config defaultUsername=testuser));
t_exitvalue(0,'Setting defaultUsername to testuser should succeed');

eSpawn(qw(add testpassword));
t_expect('Adding an entry for testpassword','Adding message');
t_expect('-re','Random password: .*','Random password');
t_expect('  Enter /help for help.','Help message');
t_expect('  Enter a password to use a custom password.','Custom password message');
t_expect('  Just press enter to use the random password.','Random password entry');
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('  Enter a username for this entry.','Username message');
t_expect('  Just press enter to store the default username (testuser)','Default username message');
t_expect('  Enter a single dot (".") to not store any username.','Single dot message');
t_expect('Username> ','Username prompt');
expect_send("\n");
t_exitvalue(0,'Adding should succeed');

ok(-e $testfile,'The file exists');

eSpawn(qw(get testpassword));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?testuser','Retrieve entry');
t_exitvalue(0,'Retrieval should succeed');

eSpawn(qw(get testpwd));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?testuser','Retrieve entry with typos');
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
t_expect('  Just press enter to keep the current username (testuser).','Keep username message');
t_expect('  Enter a single dot (".") to remove the stored username.','Remove username message');
t_expect('Username> ','Username prompt');
expect_send("newusername\n");
t_expect('Changed testpassword from 1234567890 to abcdefghij','Password change');
t_exitvalue(0,'Changing a password should succeed');

eSpawn(qw(add tsting));
t_expect('Password> ','Password prompt for second entry');
expect_send("qwertyuio\n");
t_expect('Username> ','Username prompt for second entry');
expect_send("\n");
t_exitvalue(0,'Adding a second password should succeed');

eSpawn(qw(get tist));
t_expect('-re','tsting              : qwertyuio\s+(\S+\s+)?testuser','Retrieve password fuzzy');
t_exitvalue(0,'Getting a fuzzy password should succeed');

eSpawn(qw(get testingpwd));
t_expect('-re','tsting              : qwertyuio\s+(\S+\s+)?testuser','Retrieve password with typos');
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

eSpawn(qw(config remove defaultUsername));
t_exitvalue(0,'Resetting defaultUsername should succeed');

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

eSpawn(qw(get testpassword));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?username','Retrieve entry');
t_exitvalue(0,'Retrieval should succeed');

unlink($testfile);
