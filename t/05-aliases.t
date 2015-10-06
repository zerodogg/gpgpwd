#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 51;
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

eSpawn(qw(alias testpassword aliased));
t_expect('Added an alias for "aliased" that references "testpassword"','Message about the alias being added');
t_exitvalue(0,'Adding an alias should succeed');

eSpawn(qw(alias testpassword removaltest));
t_expect('Added an alias for "removaltest" that references "testpassword"','Message about the alias being added');
t_exitvalue(0,'Adding an alias should succeed');

eSpawn(qw(remove removaltest));
t_expect('Removed removaltest (which was an alias pointing to testpassword','Main removal message');
t_exitvalue(0,'Removal should succeed');

eSpawn(qw(get removaltest));
t_expect('(no passwords found for "removaltest")','Fail to retrieve the removed alias');
t_exitvalue(0,'Retrieval of alias should succeed');

eSpawn(qw(get aliased));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?username','Retrieve entry');
t_exitvalue(0,'Retrieval of alias should succeed');

eSpawn(qw(alias aliased secondlevel));
t_expect('Added an alias for "secondlevel" that references "aliased"','Message about the alias being added');
t_exitvalue(0,'Adding an alias should succeed');

eSpawn(qw(get secondlevel));
t_expect('-re','testpassword        : 1234567890\s+(\S+\s+)?username','Retrieve entry');
t_exitvalue(0,'Retrieval of alias that references another alias should succeed');

eSpawn(qw(change secondlevel));
t_expect('"secondlevel" already exists and is an alias. You must first remove the alias before you','Change message 1');
t_expect('can add a password with that name (or you can use the "alias" command to change what','Change message 2');
t_expect('"secondlevel" is an alias for).','Change message 3');
t_exitvalue('nonzero','Change of an alias should fail');

eSpawn(qw(remove testpassword));
t_expect('Removed testpassword (with the password 1234567890)','Main removal message');
t_expect('Also removed the alias "aliased" which was pointing to "testpassword"','First layer alias message');
t_expect('Also removed the alias "secondlevel" which was pointing to "aliased"','Second layer alias message');
t_exitvalue(0,'Removal should succeed');

eSpawn(qw(get aliased));
t_expect('(no passwords found for "aliased")','Fail to retrieve the removed alias');
t_exitvalue(0,'Retrieval of alias should succeed');

eSpawn(qw(get secondlevel));
t_expect('(no passwords found for "secondlevel")','Fail to retrieve the removed alias');
t_exitvalue(0,'Retrieval of alias should succeed');

eSpawn(qw(add testpassword));
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('Username> ','Username prompt');
expect_send("username\n");
t_exitvalue(0,'Adding should succeed');

eSpawn(qw(alias doesnotexist aliased));
t_expect('There is no existing password entry for "doesnotexist"','Fail to add an alias referencing a non-existing entry');
t_exitvalue('nonzero','Adding the alias should fail');

eSpawn(qw(alias testpassword aliased));
t_expect('Added an alias for "aliased" that references "testpassword"','Message about the alias being added');
t_exitvalue(0,'Adding an alias should succeed');

eSpawn(qw(alias aliased secondlevel));
t_expect('Added an alias for "secondlevel" that references "aliased"','Message about the alias being added');
t_exitvalue(0,'Adding an alias should succeed');

eSpawn(qw(remove aliased));
t_expect('Removed aliased (which was an alias pointing to testpassword)','Main removal message');
t_expect('Also removed the alias "secondlevel" which was pointing to "aliased"','Second layer alias message');
t_exitvalue(0,'Removal should succeed');
