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

=head1 AUTHOR

Jari Turkia, C<< <jatu at hqcodeshop.fi> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-isc-dhcpclient at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Net-ISC-DHCPClient>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Net::ISC::DHCPClient


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Net-ISC-DHCPClient>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Net-ISC-DHCPClient>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Net-ISC-DHCPClient>

=item * Search CPAN

L<http://search.cpan.org/dist/Net-ISC-DHCPClient/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Jari Turkia.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

# vim: tabstop=4 shiftwidth=4 softtabstop=4 expandtab:

1; # End of Net::ISC::DHCPClient