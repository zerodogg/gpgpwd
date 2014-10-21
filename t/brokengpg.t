#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Test::More tests => 9;
use File::Temp qw(tempdir);
use File::Copy qw(move);
use FindBin;
use lib $FindBin::Bin;
use TestLib;

enable_raw_gpgpwd();

# First test with a broken gpg2 binary
my $tmpdir = tempdir('gpgpwd-testpath-XXXXXXXX',TMPDIR => 1, CLEANUP => 1);
open(my $o,'>',$tmpdir.'/gpg2');
print {$o} "#!/usr/bin/perl\n";
print {$o} "exit(1);\n";
close($o);
chmod(0700,$tmpdir.'/gpg2');
symlink($tmpdir.'/gpg2',$tmpdir.'/gpg');

$ENV{PATH} = $tmpdir.':'.$ENV{PATH};

eSpawn(qw(add testpassword));
t_expect('-re','.*exited with non-zero return value.*','Should output information about the non-zero exit value');
t_exitvalue('nonzero','Adding should not succeed');

delete($ENV{GNUPGHOME});
delete($ENV{GPG_AGENT_INFO});

# Then a broken gpg-agent binary

move($tmpdir.'/gpg2',$tmpdir.'/gpg-agent');
unlink($tmpdir.'/gpg');
eSpawn(qw(add testpassword));
t_expect('gpgpwd failed to start a gpg-agent, did not return any status information','Should output failure information');
t_exitvalue('nonzero','Command should not succeed');

# Then a gpg-agent binary that appears to work but doesn't

open($o,'>',$tmpdir.'/gpg-agent');
print {$o} "#!/usr/bin/perl\n";
print {$o} "print 'GPG_AGENT_INFO=$tmpdir/missing:-0; export GPG_AGENT_INFO';\n";
print {$o} "exit(1);\n";
close($o);
chmod(0700,$tmpdir.'/gpg-agent');

eSpawn(qw(add testpassword));
t_expect('gpgpwd failed to start a gpg-agent, it exited with the exit status 1','Should output failure information');
t_exitvalue('nonzero','Command should not succeed');

# Finally a gpg-agent binary that returns what appears to be valid data, but
# that actually isn't
my $dummyProc = open(my $dummyOut,'-|',qw(perl -e),'$0 = "gpgpwd testing dummy process"; sleep(300);');
open($o,'>',$tmpdir.'/gpg-agent');
print {$o} "#!/usr/bin/perl\n";
print {$o} "print 'GPG_AGENT_INFO=/:$dummyProc; export GPG_AGENT_INFO';\n";
print {$o} "exit(1);\n";
close($o);
chmod(0700,$tmpdir.'/gpg-agent');

eSpawn(qw(add testpassword));
t_expect('Password> ','Password prompt');
expect_send("1234567890\n");
t_expect('-re','.*exited with non-zero return value.*','Should output information about the non-zero exit value');
t_exitvalue('nonzero','Adding should not succeed');

# Kill dummyProc if needed
kill('SIGINT',$dummyProc);
