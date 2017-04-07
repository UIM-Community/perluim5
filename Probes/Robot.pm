package Perluim::Probes::Robot;

use strict;
use warnings;

use Nimbus::API;
use Nimbus::PDS;
use Nimbus::CFG;

sub new {
    my ($class,$o) = @_;
    my $this = {
        name            => $o->get("name") || $o->get("robotname") ,
        origin          => $o->get("origin"),
        addr            => $o->get("addr") || "/".$o->get("domain")."/".$o->get("hubname")."/".$o->get("robotname"),
        port            => $o->get("port") || "48000",
        version         => $o->get("version"),
        ip              => $o->get("ip") || $o->get("robotip"),
        status          => $o->get("status") || 0,
        os_major        => $o->get("os_major"),
        os_minor        => $o->get("os_minor"),
        os_user1        => $o->get("os_user1"),
        os_user2        => $o->get("os_user2"),
        os_description  => $o->get("os_description"),
        ssl_mode        => $o->get("ssl_mode"),
        device_id       => $o->get("device_id") || $o->get("robot_device_id"),
        metric_id       => $o->get("metric_id"),
        probe_list      => {},
        hubname         => "",
        hubip           => "",
        domain          => "",
        robotip         => "",
        hubrobotname    => "",
        uptime          => 0,
        started         => 0,
        os_version      => "",
        workdir         => "",
        log_level       => 0,
        source          => ""

    };
    return bless($this,ref($class) || $class);
}

1;
