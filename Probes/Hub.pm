package Perluim::Probes::Hub;

use Nimbus::API;
use Nimbus::Session;
use Perluim::Core::Events;
use Perluim::API;

sub new {
    my ($class,$o) = @_;
    my @addrArray;
    if($o->get("hubaddr")) {
        @addrArray = split("/",$o->get("hubaddr"));
    }
    my $this = {
        name        => $o->get("name") || $o->get("hubname"),
        robotname   => $o->get("robotname") || $addrArray[3],
        addr        => $o->get("addr") || $o->get("hubaddr"),
        domain      => $o->get("domain"),
        ip          => $o->get("ip") || $o->get("hubip"),
        port        => $o->get("port"),
        status      => $o->get("status"),
        version     => $o->get("version"),
        origin      => $o->get("origin"),
        source      => $o->get("source"),
        last        => $o->get("last"),
        license     => $o->get("license"),
        sec_on      => $o->get("sec_on"),
        sec_ver     => $o->get("sec_ver"),
        ssl_mode    => $o->get("ssl_mode"),
        ldap        => $o->get("ldap"),
        ldap_version => $o->get("ldap_version"),
        tunnel      => $o->get("tunnel") || "no",
        uptime      => $o->get("uptime") || 0,
        started     => $o->get("started") || 0
    };
    my $blessed = bless($this,ref($class) || $class);
    $blessed->{clean_addr} = substr($blessed->{addr},0,-4);
    return $blessed;
}

1;
