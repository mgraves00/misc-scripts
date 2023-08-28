#!/usr/bin/perl

# MIT License
# 
# Copyright (c) 2023 Michael Graves
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use Data::Dumper;

my $month  = "(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)";
my $day    = "(?: ?0?[0-9]|[123][0-9])";
my $time   = "(?:[0-9]{2}:[0-9]{2}:[0-9]{2})";
my $iso    = "(?:[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(?:\.[0-9]+)?Z)";
my $timestamp = "(?<timestamp>(?:$month $day $time|$iso))";
my $host   = "(?<host>[a-zA-Z0-9]+)";
my $prog   = "(?<prog>[a-zA-Z0-9-_]+)";
my $optpid = "(?<optpid>(?:\[[0-9]+\])?)";
my $msg    = "(?<msg>.*\$)";

my $smtp_id   = "(?<smtpid>[a-zA-Z0-9]+)";
my $smtp_thrd = "(?<smtpthrd>[a-zA-Z0-9-_]+)";
#my $smtp_cmd  = "(?<smtpcmd>([a-zA-Z0-9-_]+)(?=([a-zA-Z0-9-_]+=)))";
my $smtp_cmd  = "(?<smtpcmd>([a-zA-Z0-9-_]+))";
my $smtp_args = "(?<smtpargs>(([a-zA-Z0-9-_]+=(?:\"[^\"]+\"|[^ ]+)) ?)+)";
my $rest    = "(?<rest>.*\$)";

my %smtp;

my @local_accounts = [ root, daemon, operator, bin, build, sshd, _portmap, _identd, _rstatd,
                        _rusersd, _fingerd, _x11, _unwind, _switchd, _traceroute, _ping, _rebound,
                        _unbound, _dpb, _pbuild, _pfetch, _pkgfetch, _pkguntar, _spamd, www, _isakmpd,
                        _syslogd, _pflogd, _bgpd, _tcpdump, _dhcp, _mopd, _tftpd, _rbootd, _ppp, _ntp,
                        _ftp, _ospfd, _hostapd, _dvmrpd, _ripd, _relayd, _ospf6d, _snmpd, _ypldap,
                        _rad, _smtpd, _rwalld, _nsd, _ldpd, _sndio, _ldapd, _iked, _iscsid, _smtpq,
                        _file, _radiusd, _eigrpd, _vmd, _tftp_proxy, _ftp_proxy, _sndiop, _syspatch,
                        _slaacd, nobody, _rspamd, _dkimsign, _dovecot, _dovenull, dsync ];

foreach my $line ( <STDIN> ) {
        chomp ($line);
        my @V = ($line =~ m/$timestamp $host $prog$optpid: $msg/);
        my $timestamp = $+{timestamp};
        my $host = $+{host};
        my $prog = $+{prog};
        my $optpid = $+{optpid};
        my $msg = $+{msg};
        if ($prog eq "smtpd") {
                my @Q = ($msg =~ m/^$smtp_id $smtp_thrd $smtp_cmd $smtp_args/);
                my $smtpid = $+{smtpid};
                my $smtpthrd = $+{smtpthrd};
                my $smtpcmd = $+{smtpcmd};
                my $smtpargs = $+{smtpargs};
                if (length($smtpid) > 0) {
                        my @args = ( $smtpargs =~ m/([a-zA-Z0-9-_]+=(?:\"[^\"]+\"|[^ ]+))/g );
                        my %x = map { my ($k, $v) = split("=",$_); $k => $v } @args;
                        $smtp{$smtpid}->{$smtpcmd} = \%x;
                        $smtp{$smtpid}->{$smtpcmd}->{'timestamp'} = $timestamp;
                        $smtp{$smtpid}->{$smtpcmd}->{'raw'} = $msg;
                }
        }
}
#print Dumper(\%smtp);
my $counters;
$counters->{failedauth} = 0;
$counters->{successauth} = 0;
$counters->{systemaccounts} = 0;
$counters->{deliveryfail} = 0;
my %acct_hash = map { $_ => 1 } @local_accounts;
foreach my $k ( keys %smtp ) {
        # record authentication failure attempts
        if ( defined($smtp{$k}{'failed-command'}) ) {
                $counters->{failedauth}++;
                $counters->{failedfrom}->{$smtp{$k}->{connected}->{address}}++;
                if ($smtp{$k}{failed-command}{result} =~ /Authentication failed/) {
                        $counters->{failedreason}->{badpass}++;
                }
                $counters->{faileduser}->{$smtp{$k}->{authentication}->{user}}++;
        }
        # recorded successful attempts, from addresses and accountes
        if ( $smtp{$k}{'authentication'}{'result'} eq "ok" ) {
                $counters->{successauth}++;
                $counters->{successfrom}->{$smtp{$k}->{connected}->{address}}++;
                $counters->{successuser}->{$smtp{$k}->{authentication}->{user}}++;
        }
        # check delivery status
        if ( $smtp{$k}{'delivery'}{'result'} eq "TempFail" ) {
                $counters->{deliveryfailure}++;
                $counters->{tempfail}++;
        } elsif ( $smtp{$k}{'delivery'}{'result'} eq "PermFail" ) {
                $counters->{deliveryfailure}++;
                $counters->{permfail}++;
        } elsif ( $smtp{$k}{'delivery'}{'result'} =~ /"Ok"|Ok/ ) {
                $counters->{deliverysuccess}++;
        } else {
                $counters->{deliveryfailure}++;
                $counters->{other}++;
        }
        # check to see if system accounts were attempted
        if (defined($acct_hash{$smtp{$k}->{authentication}->{user}})) {
                $counters->{systemaccounts}++;
        }
}
# just dump for now

print "Delivery Success: $counters->{deliverysuccess}\n";
print "Delivery Failures: $counters->{deliveryfailure}\n";
print "Success Authentication: $counters->{successauth}\n";
print "Failed Authentication: $counters->{failedauth}\n";
print "System Accounts: $counters->{systemaccounts}\n";
print "Other Failures: $counters->{other}\n";

print "Success accounts:\n";
foreach $k (sort { $counters->{successuser}->{$b} <=> $counters->{successuser}->{$a} } keys %{$counters->{successuser}} ) {
        printf("%25s = %d\n",$k,$counters->{successuser}->{$k});
}
print "\n";

print "Failed accounts:\n";
foreach $k (sort { $counters->{faileduser}->{$b} <=> $counters->{faileduser}->{$a} } keys %{$counters->{faileduser}} ) {
        if ($k == "") {
                $val = "''";
        } else {
                $val = $k;
        }
        printf("%25s = %d\n",$val,$counters->{faileduser}->{$k});
}
print "\n";

print "Success Addresses:\n";
foreach $k (sort { $counters->{successfrom}->{$b} <=> $counters->{successfrom}->{$a} } keys %{$counters->{successfrom}} ) {
        printf("%25s = %d\n",$k,$counters->{successfrom}->{$k});
}
print "\n";

print "Failed Addresses:\n";
foreach $k (sort { $counters->{failedfrom}->{$b} <=> $counters->{failedfrom}->{$a} } keys %{$counters->{failedfrom}} ) {
        printf("%25s = %d\n",$k,$counters->{failedfrom}->{$k});
}
print "\n";

#print Dumper($counters);

