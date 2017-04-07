package Perluim::Core::Request;

use strict;
use warnings;

use Nimbus::API;
use Nimbus::PDS;
use Perluim::Core::Events;
use Perluim::Core::Response;
use Scalar::Util qw(reftype looks_like_number);

our %nimport_map = (
    48000 => "controller",
    48001 => "spooler",
    48002 => "hub"
);

sub new {
    my ($class,$argRef) = @_;
    if(defined $argRef->{addr} && not defined $argRef->{robot}) {
        my @addrArray = split("/",$argRef->{addr});
        if(scalar @addrArray >= 3) {
            $argRef->{robot} = $addrArray[2];
        }
    }
    my $this = {
        robot   => $argRef->{robot},
        addr    => $argRef->{addr},
        port    => defined $argRef->{port} ? $argRef->{port} : 48000,
        callback => defined $argRef->{callback} ? $argRef->{callback} : "get_info",
        retry   => defined $argRef->{retry} ? $argRef->{retry} : 1,
        timeout => defined $argRef->{timeout} ? $argRef->{timeout} : 5,
        RC      => undef,
        Ret     => undef,
        Emitter => Perluim::Core::Events->new
    };
    return bless($this,ref($class) || $class);
}

sub emit {
    my ($self,$eventName,$data) = @_;
    $self->{Emitter}->emit($eventName,$data);
}

sub on {
    my ($self,$eventName,$callbackRef) = @_;
    $self->{Emitter}->on($eventName,$callbackRef);
}

sub setTimeout {
    my ($self,$timeOut) = @_;
    if(defined $timeOut) {
        $self->{timeout} = $timeOut;
        return 1;
    }
    return 0;
}

sub setRetry {
    my ($self,$retryInt) = @_;
    if(defined $retryInt) {
        $self->{retry} = $retryInt;
        return 1;
    }
    return 0;
}

sub _pdsFromHash {
    my ($self,$PDSData) = @_;
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

sub send {
    my ($self,$callRef,$PDSData) = @_;
    my ($overbus,$timeout,$PDS);

    if(ref($callRef) eq "HASH") {
        $overbus = defined $callRef->{overbus} ? $callRef->{overbus} : 1;
        $timeout = defined $callRef->{timeout} ? $callRef->{timeout} : $self->{timeout};
    }
    else {
        $overbus = $callRef; 
        $timeout = $self->{timeout};
    }
    
    if(ref($PDSData) eq "HASH") {
        $PDS = $self->_pdsFromHash($PDSData);
    }
    else {
        $PDS    = defined $PDSData ? $PDSData : Nimbus::PDS->new;
    }
    my $i       = 0;
    my $RC      = NIME_ERROR;
    my $Ret     = undef;
    

    $self->emit('log',"start new request with timeout set to $timeout, callback => $self->{callback}\n");
    $| = 1; # Auto-flush ! 

    if($overbus && defined $self->{addr}) {
        $self->emit('log',"nimNamedRequest triggered\n");
        for(;$i < $self->{retry};$i++) {
            eval {
                local $SIG{ALRM} = sub { 
                    $self->emit('log','die emitted...');
                    die "alarm\n";
                }; 
                alarm $timeout;
                ($RC,$Ret) = nimNamedRequest(
                    $self->{addr},
                    $self->{callback},
                    $PDS->data
                );
                alarm 0;
            };
            if ($@) {
                $self->{RC}     = NIME_EXPIRED;
                $self->emit('log',"nimNamedRequest timeout\n");
                die unless $@ eq "alarm\n";   # propagate unexpected errors
            }
            else {
                $self->{Ret}    = $Ret;
                $self->{RC}     = $RC;
            }

            $self->emit('log',"terminated with RC => $RC\n");
            last if $RC == NIME_OK;
            last if $RC != NIME_COMERR && $RC != NIME_ERROR;

            sleep(1);
        }
    }
    elsif(defined $self->{port} && ( defined $self->{robot} || defined $nimport_map{ $self->{port} } )) {
        $self->emit('log',"nimRequest triggered\n");
        for(;$i < $self->{retry};$i++) {
            my $robotNFO = defined $self->{robot} ? $self->{robot} : $nimport_map{ $self->{port} };
            eval {
                local $SIG{ALRM} = sub { 
                    $self->emit('log',"die emitted...\n");
                    die "alarm\n";
                }; 
                alarm $timeout;
                $self->emit('log',"robot => $robotNFO\n");
                $self->emit('log',"port => $self->{port}\n");
                ($RC,$Ret) = nimRequest(
                    $robotNFO,
                    $self->{port},
                    $self->{callback},
                    $PDS->data
                );
                alarm 0;
            };
            if ($@) {
                $self->{RC}     = NIME_EXPIRED;
                $self->emit('log',"nimRequest timeout\n");
                die unless $@ eq "alarm\n";   # propagate unexpected errors
            }
            else {
                $self->emit('log',"finished with no timeout\n");
                $self->{Ret}    = $Ret;
                $self->{RC}     = $RC;
            }

            $self->emit('log',"terminated with RC => $RC\n");
            last if $RC == NIME_OK;
            last if $RC != NIME_COMERR && $RC != NIME_ERROR;

            sleep(1);
        }
    }
    else {
        $self->emit('log',"missing request data to launch a new request!\n");
    }
    my $response = Perluim::Core::Response->new({
        rc => $self->{RC},
        data => $self->{Ret}
    });
    $self->emit('done',$response);
    return $response;
}

1;
