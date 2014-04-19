package TestLib;
use strict;
use warnings;
use 5.010;
use Exporter qw(import);
use Expect;
use Cwd qw(realpath);
use File::Basename qw(dirname);
our @EXPORT = qw(t_wait_eof t_expect t_exitvalue eSpawn getCmd expect_send set_gpgpwd_database_path);

our $e;
our $testfile;

sub t_exitvalue
{
    my $value = shift;
    my $name = shift;
    $e->expect(10,undef);
    if ($value eq 'nonzero')
    {
        main::ok($e->exitstatus != 0, $name);
    }
    else
    {
        main::is($e->exitstatus,$value,$name);
    }
    $e = undef;
}

sub set_gpgpwd_database_path
{
    $testfile = shift;
}

sub expect_send
{
    return $e->send(@_);
}

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
        main::ok(1,$name);
    }
    else
    {
        main::is($e->before,$tests[-1],$name);
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
    no warnings;
    return ($dir.'/../gpgpwd','--no-git','--password-file',$testfile,@_);
}

1;
