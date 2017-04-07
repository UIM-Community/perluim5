package Perluim::Probes::Probe;

use strict;
use warnings;

use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

sub new {
    my ($class,$name,$o,$addr) = @_;
    my @addrArray = split("/",$addr);
    my $this = {
        name            => $o->{$name}{"name"},
        addr            => $addrArray[0]."/".$addrArray[1]."/".$addrArray[2]."/".$addrArray[3],
        robotname       => $addrArray[3],
        description     => $o->{$name}{"description"}  || "",
        group           => lc $o->{$name}{"group"}  || "",
        active          => $o->{$name}{"active"},
        type            => $o->{$name}{"type"},
        command         => $o->{$name}{"command"},
        config          => lc $o->{$name}{"config"},
        logfile         => lc $o->{$name}{"logfile"},
        workdir         => lc $o->{$name}{"workdir"},
        arguments       => $o->{$name}{"arguments"} || "",
        pid             => $o->{$name}{"pid"},
        times_started   => $o->{$name}{"times_started"},
        last_started    => $o->{$name}{"last_started"} || 0,
        pkg_name        => $o->{$name}{"pkg_name"} || "",
        pkg_version     => $o->{$name}{"pkg_version"} || "",
        pkg_build       => $o->{$name}{"pkg_build"} || "",
        process_state   => $o->{$name}{"process_state"} || "unknown",
        port            => $o->{$name}{"port"},
        times_activated => $o->{$name}{"times_activated"},
        timespec        => $o->{$name}{"timespec"},
        last_action     => $o->{$name}{"last_action"},
        is_marketplace  => $o->{$name}{"is_marketplace"},
        local_cfg       => undef
    };
    return bless($this,ref($class) || $class);
}

1;
