package Perluim::API;

use strict;
use warnings;
use Carp;
use vars qw(@ISA @EXPORT $AUTOLOAD);
require 5.010;
require Exporter;
require DynaLoader;
require AutoLoader;

use Nimbus::API;
use Nimbus::CFG;
use Nimbus::PDS;

use Perluim::Core::Request;
use Perluim::Core::Probe;
use Perluim::Logger;
use Perluim::Probes::Hub;
use Perluim::Probes::Robot;

our $Logger;
our $Debug = 0;
@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
    uimRequest
    uimProbe
    uimLogger
    LogFATAL
    LogERROR
    LogWARN
    LogINFO
    LogDEBUG
    LogNOLEVEL
    LogSUCCESS
    toMilliseconds
    doSleep
    strBeginWith
    createDirectory
    terminalStdout
    getDate
    rndStr
    nimId
    generateAlarm
    pdsFromHash
    getHubs
    getRobots
    getLocalRobot
);
no warnings 'recursion';

use constant {
	LogFATAL    => 0,
	LogERROR    => 1,
	LogWARN     => 2,
	LogINFO	    => 3,
	LogDEBUG    => 4,
	LogNOLEVEL  => 5,
	LogSUCCESS  => 6
};

sub AUTOLOAD {
	no strict 'refs'; 
	
	my $sub = $AUTOLOAD;
    my $constname;
    ($constname = $sub) =~ s/.*:://;
	
	$!=0; 
    my ($val,$rc) = constant($constname, @_ ? $_[0] : 0);
    if ($rc != 0) {
		$AutoLoader::AUTOLOAD = $sub;
		goto &AutoLoader::AUTOLOAD;
    }
    *$sub = sub { $val };
    goto &$sub;
}

sub uimRequest {
    my ($argRef) = @_;
    return Perluim::Core::Request->new($argRef);
}

sub uimProbe {
    my ($argRef) = @_;
    my $probe = Perluim::Core::Probe->new($argRef);
    $probe->setLogger( $Logger ) if defined $Logger;
    return $probe;
}

sub uimLogger {
    my ($argRef) = @_;
    my $log = Perluim::Logger->new($argRef);
    if(!defined $Logger) {
        $Logger = $log;
    }
    return $log;
}

sub getLocalRobot {
    my $req = uimRequest({
        addr => "controller",
        callback => "get_info",
        retry => 3,
        timeout => 5
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send(1);
    return $res->rc(), $res->is(NIME_OK) ? Perluim::Probes::Robot->new($res->pdsData()) : undef;
}

sub getHubs {
    my $req = uimRequest({
        addr => "hub",
        callback => "gethubs",
        retry => 3,
        timeout => 5
    });
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send(1);
    if( $res->is(NIME_OK) ) {
        my @Hubslist = ();
        for( my $i = 0; my $HubPDS = $res->pdsData()->getTable("hublist",PDS_PDS,$i); $i++) {
            push(@Hubslist,Perluim::Probes::Hub->new($HubPDS));
        }
        return $res->rc(),@Hubslist;
    }
    return $res->rc(),undef;
}

sub getRobots {
    my ($RC,@Hubs) = getHubs(); 
    if($RC == NIME_OK) {
        foreach my $hub (@Hubs) {
            # $hub->getRobots();
        }
        # get robots from hub!
    }   
    return $RC,undef;
}

sub toMilliseconds {
    my ($second) = @_; 
    return $second * 1000;
}

sub pdsFromHash {
    my ($PDSData) = @_;
    my $PDS = Nimbus::PDS->new;
    for my $key (keys %{ $PDSData }) {
        my $val = $PDSData->{$key};
        if(ref($val) eq "HASH") {
            $PDS->put($key,$val,PDS_PDS);
        }
        else {
            $PDS->put($key,$val,looks_like_number($val) ? PDS_INT : PDS_PCH);
        }
    }
    return $PDS;
}

sub doSleep {
    my ($self,$sleepTime) = @_;
    $| = 1;
    while($sleepTime--) {
        sleep(1);
    }
}

sub strBeginWith {
    return substr($_[0], 0, length($_[1])) eq $_[1];
}

sub createDirectory {
    my ($path) = @_;
    my @dir = split("/",$path);
    my $track = "";
    foreach(@dir) {
        my $path = $track.$_;
        if( !(-d $path) ) {
            mkdir($path) or die "Unable to create $_ directory!";
        }
        $track .= "$_/";
    }
}

sub terminalStdout {
    my $input;
    while(<>) {
        s/\s*$//;
        $input = $_;
        if(defined $input && $input ne "") {
            return $input;
        }
    }
}

sub getDate {
    my ($self) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timestamp   = sprintf ( "%04d%02d%02d %02d:%02d:%02d",$year+1900,$mon+1,$mday,$hour,$min,$sec);
	$timestamp     =~ s/\s+/_/g;
	$timestamp     =~ s/://g;
    return $timestamp;
}

sub rndStr { 
    return join'', @_[ map{ rand @_ } 1 .. shift ] 
}

sub nimId {
    my $A = rndStr(10,'A'..'Z',0..9);
    my $B = rndStr(5,0..9);
    return "$A-$B";
}

sub generateAlarm {
    my ($subject,$hashRef) = @_;

    my $PDS = Nimbus::PDS->new(); 
    my $nimid = nimId();

    $PDS->string("nimid",$nimid);
    $PDS->number("nimts",time());
    $PDS->number("tz_offset",0);
    $PDS->string("subject","$subject");
    $PDS->string("md5sum","");
    $PDS->string("user_tag_1",$hashRef->{usertag1} || "");
    $PDS->string("user_tag_2",$hashRef->{usertag2} || "");
    $PDS->string("source",$hashRef->{source} || $hashRef->{robot} || "");
    $PDS->string("robot",$hashRef->{robot} || "");
    $PDS->string("prid",$hashRef->{probe} || "");
    $PDS->number("pri",$hashRef->{severity} || 0);
    $PDS->string("dev_id",$hashRef->{dev_id} || "");
    $PDS->string("met_id",$hashRef->{met_id} || "");
    if ($hashRef->{supp_key}) { $PDS->string("supp_key",$hashRef->{supp_key}) };
    $PDS->string("suppression",$hashRef->{suppression} || "");
    $PDS->string("origin",$hashRef->{origin} || "");
    $PDS->string("domain",$hashRef->{domain} || "");

    my $AlarmPDS = Nimbus::PDS->new(); 
    $AlarmPDS->number("level",$hashRef->{severity} || 0);
    $AlarmPDS->string("message",$hashRef->{message});
    $AlarmPDS->string("subsys",$hashRef->{subsystem} || "1.1.");
    if(defined $hashRef->{token}) {
        $AlarmPDS->string("token",$hashRef->{token});
    }

    $PDS->put("udata",$AlarmPDS,PDS_PDS);

    return ($PDS,$nimid);
}    

1;
