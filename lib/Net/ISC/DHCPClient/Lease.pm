package Net::ISC::DHCPClient::Lease;

use 5.006;
use strict;
use warnings;


=head1 NAME

Net::ISC::DHCPClient - ISC dhclient lease object

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    $self->{INTERFACE} = undef;
    $self->{FIXED_ADDRESS} = undef;
    $self->{OPTION} = {};
    $self->{RENEW} = undef;
    $self->{REBIND} = undef;
    $self->{EXPIRE} = undef;

    bless ($self, $class);

    return $self;
}

sub interface {
    my $self = shift;
    if (@_) { $self->{INTERFACE} = shift }
    return $self->{INTERFACE};
}
sub fixed_address {
    my $self = shift;
    if (@_) { $self->{FIXED_ADDRESS} = shift }
    return $self->{FIXED_ADDRESS};
}
sub option {
    my $self = shift;
    if (@_) { $self->{OPTION} = shift }
    return $self->{OPTION};
}
sub renew {
    my $self = shift;
    if (@_) { $self->{RENEW} = shift }
    return $self->{RENEW};
}
sub rebind {
    my $self = shift;
    if (@_) { $self->{REBIND} = shift }
    return $self->{REBIND};
}
sub expire {
    my $self = shift;
    if (@_) { $self->{EXPIRE} = shift }
    return $self->{EXPIRE};
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

1; # End of Net::ISC::DHCPClient::Lease
