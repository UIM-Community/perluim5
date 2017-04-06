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

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
    uimRequest
    uimProbe
    LogFATAL
    LogERROR
    LogWARN
    LogINFO
    LogDEBUG
    LogNOLEVEL
    LogSUCCESS
    toMilliseconds
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

sub new {
    my ($class) = @_;
    my $this = {};
    return bless($this,ref($class) || $class);
}

sub toMilliseconds {
    my ($second) = @_; 
    return $second * 1000;
}

sub uimRequest {
    my ($argRef) = @_;
    return Perluim::Core::Request->new($argRef);
}

sub uimProbe {
    my ($argRef) = @_;
    return Perluim::Core::Probe->new($argRef);
}

1;
