package Perluim::Probes::Hub;

use Nimbus::API;
use Nimbus::Session;
use Perluim::Core::Events;
use Perluim::API;

our $Logger;
our $Debug      = 0;
our $Overbus    = 1;

sub new {
    my ($class,$pds) = @_;
    my @addrArray;
    if($pds->get("hubaddr")) {
        @addrArray = split("/",$pds->get("hubaddr"));
    }
    my $this = {
        name        => $pds->get("name") || $pds->get("hubname"),
        robotname   => $pds->get("robotname") || $addrArray[3],
        addr        => $pds->get("addr") || $pds->get("hubaddr"),
        domain      => $pds->get("domain"),
        ip          => $pds->get("ip") || $pds->get("hubip"),
        port        => $pds->get("port"),
        status      => $pds->get("status"),
        version     => $pds->get("version"),
        origin      => $pds->get("origin"),
        source      => $pds->get("source"),
        last        => $pds->get("last"),
        license     => $pds->get("license"),
        sec_on      => $pds->get("sec_on"),
        sec_ver     => $pds->get("sec_ver"),
        ssl_mode    => $pds->get("ssl_mode"),
        ldap        => $pds->get("ldap"),
        ldap_version => $pds->get("ldap_version"),
        tunnel      => $pds->get("tunnel") || "no",
        uptime      => $pds->get("uptime") || 0,
        started     => $pds->get("started") || 0,
        Emitter     => Perluim::Core::Events->new
    };
    my $blessed = bless($this,ref($class) || $class);
    $blessed->{clean_addr} = substr($blessed->{addr},0,-4);
    return $blessed;
}

# events functions
sub emit {
    my ($self,$eventName,$data) = @_;
    $self->{Emitter}->emit($eventName,$data);
}

sub on {
    my ($self,$eventName,$callbackRef) = @_;
    $self->{Emitter}->on($eventName,$callbackRef);
}

# hub::addrobot callback
our $IAddRobot = {

};

sub addrobot {
    my ($self,$options) = @_; 
    if(!defined $options->{name} || !defined $options->{ip}) {
        $self->emit('log',"invalid sub arguments (name|ip) for hub::addrobot\n");
        return NIME_INVAL,undef;
    }
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "addrobot"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,assignHash($options,$IAddRobot));
    return $res->rc();
}

# hub::check_response callback
our $ICheckResponse = {
    timeout => 5
};

sub check_response {
    my ($self,$options) = @_; 
    if(!defined $options->{addr}) {
        $self->emit('log',"invalid sub arguments (addr) for hub::check_response\n");
        return NIME_INVAL,undef;
    }
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "check_response"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,assignHash($options,$ICheckResponse));
    return $res->rc(),$res->hashData();
}

# hub::checkhub callback 
sub checkhub {
    my ($self,$options) = @_; 
    if(!defined $options->{hubname} || !defined $options->{domain}) {
        $self->emit('log',"invalid sub arguments (hubname|domain) for hub::checkhub\n");
        return NIME_INVAL,undef;
    }
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "checkhub"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,$options);
    return $res->rc();
}

# hub::clear_subscribers
sub clear_subscribers {
    my ($self) = @_;
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "clear_subscribers"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus);
    return $res->rc();
}

# hub::clear_subscribers
sub clear_usubject {
    my ($self,$options) = @_;
    if(!defined $options->{subject}) {
        $self->emit('log',"invalid sub arguments (subject) for hub::clear_usubject\n");
        return NIME_INVAL,undef;
    }
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "clear_usubject"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,$options);
    return $res->rc();
}

# hub::count_ldap_groups 
our $ICountLdapGroups = {
    count_max => 5,
    force_recount => 0
};

sub count_ldap_groups {
    my ($self,$options) = @_;
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "count_ldap_groups"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,assignHash($options,$ICountLdapGroups));
    return $res->rc(),$res->hashData();
}

# hub::get_perf_data
our $IGetPerfData = {
    day => 1
};

sub get_perf_data {
    my ($self,$options) = @_;
    my $req = uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "get_perf_data"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,assignHash($options,$IGetPerfData));
    return $res->rc(),$res->pdsData();
}

# hub::getrobots
sub getrobots {
    my ($self,$options) = @_;
    my $req = Perluim::API::uimRequest({
        addr => $self->{addr},
        robot => $self->{robotname},
        port => 48002,
        callback => "getrobots"
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send($Overbus,Perluim::API::assignHash($options));

    # Create robot here!
    if( $res->is(NIME_OK) ) {
        my @RobotsArray = ();
        for( my $i = 0; my $RobotPDS = $res->pdsData()->getTable("robotlist",PDS_PDS,$i); $i++) {
            push(@Hubslist,Perluim::Probes::Robot->new($RobotPDS));
        }
        return $res->rc(),@RobotsArray;
    }
    return $res->rc(),undef;
}

1;
