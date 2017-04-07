package Perluim::Core::Response;

use strict;
use warnings;

use Nimbus::API;
use Nimbus::PDS;

sub new {
    my ($class,$argRef) = @_;
    my $this = {
        _rc => $argRef->{rc},
        _data => $argRef->{data}
    };
    return bless($this,ref($class) || $class);
}

sub rc {
    my ($self) = @_;
    return $self->{_rc};
}

sub pdsData {
    my ($self) = @_;
    my $PDS = Nimbus::PDS->new($self->{_data});
    return $PDS;
}

sub hashData {
    my ($self) = @_;
    my $Hash = Nimbus::PDS->new($self->{_data})->asHash();
    return $Hash;
}

sub is {
    my ($self,$state) = @_;
    if(!defined $state) {
        $state = NIME_OK;
    }
    return $self->{_rc} == $state ? 1 : 0;
}

1;
