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

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(
    uimRequest
    uimProbe
);
no warnings 'recursion';

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

sub uimRequest {
    my ($argRef) = @_;
    return Perluim::Core::Request->new($argRef);
}

sub uimProbe {
    my ($name,$version) = @_;
}

1;
