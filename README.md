# Net-ISC-DHCPClient
Net::ISC::DHCPClient Perl module for reading ISC dhclient leases

## Example code
This code iterates all interfaces on a machine and determines if a found
interface has DHCP-assigned IPv4 or IPv6 address in it.

    use Net::Interface qw(full_inet_ntop ipV6compress type :afs :iffs :iffIN6 :iftype :scope);
    use Net::ISC::DHCPClient;
    
    my @interfaces = Net::Interface->interfaces();
    my @paths_to_attempt = ('/var/lib/dhclient', '/var/lib/dhcp', '/var/lib/NetworkManager');
    for my $if (@$interfaces) {
        my $dhclient = Net::ISC::DHCPClient->new(
            leases_path => \@paths_to_attempt,
            interface   => $if->{name},
            af          => ['inet', 'inet6']
        );
        printf("Interface %s is DHCP.", $if->{name}) if ($dhclient->is_dhcp('inet'));
    }