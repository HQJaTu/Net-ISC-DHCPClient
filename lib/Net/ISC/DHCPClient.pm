package Net::ISC::DHCPClient;

use 5.006;
use strict;
use warnings;


=head1 NAME

Net::ISC::DHCPClient - ISC dhclient lease reader

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


use Net::ISC::DHCPClient::Lease;
use Time::Local;


sub new {
    my ($class, %opts) = @_;

    die "Missing leases_path!" if (!defined($opts{leases_path}));

    my $self = {};
    $self->{INTERFACE} = defined($opts{interface}) ? $opts{interface} : undef;
    $self->{leases_path} = $opts{leases_path};
    $self->{leases} = undef;
    bless ($self, $class);

    $self->leases();
    $self->{leases} = $self->_read_lease_file($self->{leases_path}, $self->{INTERFACE});

    return $self;
}


sub is_dhcp($;$)
{
    my ($self, $inteface_to_query) = @_;

    if (defined($inteface_to_query) &&
        defined($self->{INTERFACE}) &&
        $self->{INTERFACE} ne $inteface_to_query) {
        die "Cannot query $inteface_to_query.";
    }
    if (defined($self->{INTERFACE})) {
        return scalar(@{$self->{leases}}) > 0;
    }

    die "Need interface!" if (!defined($inteface_to_query));

    # Iterate all found leases and look for given interface
    for my $lease (@{$self->leases}) {
        return 1 if ($lease->{INTERFACE} eq $inteface_to_query);
    }

    return 0;
}

sub leases($)
{
    my ($self) = @_;

    return $self->{leases};
}


sub _read_lease_file($$;$)
{
    my ($self, $path, $interface) = @_;
    my @lease_files;
    my $leases = [];

    # Search for matching .lease files
    my $leasefile_re1;
    my $leasefile_re2;
    if ($interface) {
        $leasefile_re1 = qr/^dhclient-(.*)?-($interface)\.lease$/;
        $leasefile_re2 = qr/^dhclient\.($interface)\.leases$/;
    } else {
        $leasefile_re1 = qr/^dhclient-(.*)?-(.+)\.lease$/;
        $leasefile_re2 = qr/^dhclient\.(.+)\.leases$/;
    }

    my @paths_to_attempt;
    if (ref($path) eq "ARRAY") {
        @paths_to_attempt = @$path;
    } else {
        @paths_to_attempt = ($path);
    }
    foreach my $lease_path (@paths_to_attempt) {
        next if (! -d $lease_path || ! -X $lease_path);
        opendir(my $dh, $lease_path) or
            die "Cannot read lease directory $lease_path. Error: $!";
        my @all_files = readdir($dh);
        @lease_files = grep { /$leasefile_re1/ && -f "$lease_path/$_" } @all_files;
        @lease_files = grep { /$leasefile_re2/ && -f "$lease_path/$_" } @all_files if (!@lease_files);
        closedir($dh);

        if (@lease_files) {
            @lease_files = map("$lease_path/$_", @lease_files);
            last;
        }
    }

    for my $leaseFile (@lease_files) {
        open (LEASEFILE, $leaseFile) or
            die "Cannot open leasefile $leaseFile. Error: $!";

        my $currentLease;
        my $hasLease = 0;
        while (<LEASEFILE>) {
            chomp();
            if (/^lease \{/) {
                $hasLease = 1;
                $currentLease = Net::ISC::DHCPClient::Lease->new();
                next;
            }
            if (/^\}/) {
                # dhclient will append lease information, newest is last.
                # unshift() will place newest first.
                unshift(@$leases, $currentLease) if ($hasLease);
                $hasLease = 0;
                next;
            }

            if (!$hasLease) {
                next;
            }

            s/^\s+//;   # Eat starting whitespace

            SWITCH: {
                # interface "eth1";
                /^interface\s+"(.+)";/ && do {
                    $currentLease->{INTERFACE} = $1;
                    last SWITCH;
                };
                # fixed-address 213.28.228.27;
                /^fixed-address\s+(.+);/ && do {
                    $currentLease->{FIXED_ADDRESS} = $1;
                    last SWITCH;
                };
                # option subnet-mask 255.255.255.0;
                (/^option\s+(\S+)\s*(.+);/) && do {
                    $currentLease->{OPTION}{$1} = $2;
                    last SWITCH;
                };
                # renew 5 2002/12/27 06:25:31;
                (m#^renew\s+(\d+)\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);#) && do {
                    my $leaseTime = timegm($7, $6, $5, $4, $3-1, $2);
                    $currentLease->{RENEW} = $leaseTime;
                    last SWITCH;
                };
                # rebind 5 2002/12/27 06:25:31;
                (m#^rebind\s+(\d+)\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);#) && do {
                    my $leaseTime = timegm($7, $6, $5, $4, $3-1, $2);
                    $currentLease->{REBIND} = $leaseTime;
                    last SWITCH;
                };
                # renew 5 2002/12/27 06:25:31;
                (m#^expire\s+(\d+)\s+(\d+)/(\d+)/(\d+)\s+(\d+):(\d+):(\d+);#) && do {
                    my $leaseTime = timegm($7, $6, $5, $4, $3-1, $2);
                    $currentLease->{EXPIRE} = $leaseTime;
                    last SWITCH;
                };
            }
        }
    }

    close (LEASEFILE);

    return $leases;
}

# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

1;
