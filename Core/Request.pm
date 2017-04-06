package Perluim::Core::Request;

use Nimbus::API;
use Nimbus::PDS;
use Data::Dumper;
use Perluim::Core::Events;
use Scalar::Util qw(reftype looks_like_number);

sub new {
    my ($class,$argRef) = @_;
    if(defined $argRef->{addr} && not defined $argRef->{robot}) {
        my @addrArray = split("/",$argRef->{addr});
        if(scalar @addrArray >= 3) {
            $argRef->{robot} = $addrArray[2];
        }
    }
    my $this = {
        robot => $argRef->{robot},
        addr => $argRef->{addr},
        port => defined $argRef->{port} ? $argRef->{port} : 48000,
        callback => defined $argRef->{callback} ? $argRef->{callback} : "get_info",
        retry => defined $argRef->{retry} ? $argRef->{retry} : 1,
        timeout => defined $argRef->{timeout} ? $argRef->{timeout} : 5,
        RC => undef,
        Ret => undef,
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

sub getData {
    my ($self) = @_;
    if(defined $self->{Ret}) {
        my $Hash = Nimbus::PDS->new($self->{Ret})->asHash();
        return $Hash;
    }
    $self->emit('log',"unable to find data\n");
    return undef;
}

sub send {
    my ($self,$callRef,$PDSData) = @_;
    my ($overbus,$timeout,$PDS);

    if(ref($callRef) == "HASH") {
        $overbus = defined $callRef->{overbus} ? $callRef->{overbus} : 1;
        $timeout = defined $callRef->{timeout} ? $callRef->{timeout} : $self->{timeout};
    }
    else {
        $overbus = $callRef; 
        $timeout = $self->{timeout};
    }
    
    if(ref($PDSData) eq "HASH") {
        $PDS = Nimbus::PDS->new;
        for my $key (keys %{ $PDSData }) {
            my $val = $PDSData->{$key};
            $self->emit('log',"PDS Dump => key: $key and val: $val\n");
            if(ref($val) eq "HASH") {
                $PDS->put($key,$val,PDS_PDS);
            }
            else {
                $PDS->put($key,$val,looks_like_number($val) ? PDS_INT : PDS_PCH);
            }
        }
    }
    else {
        $PDS    = defined $PDSData ? $PDSData : Nimbus::PDS->new;
    }
    my $i       = 0;
    my $RC      = NIME_ERROR;
    my $Ret     = undef;
    

    $self->emit('log',"start new request with timeout set to $timeout\n");
    $| = 1; # Auto-flush ! 

    if($overbus && defined $self->{addr}) {
        $self->emit('log',"nimNamedRequest triggered\n");
        for(;$i < $self->{retry};$i++) {
            eval {
                local $SIG{ALRM} = sub { die "alarm\n" }; 
                alarm $timeout;
                ($RC,$Ret) = nimNamedRequest(
                    $self->{addr},
                    $self->{callback},
                    $PDS->data
                );
                alarm 0;
            };
            if ($@) {
                die unless $@ eq "alarm\n";   # propagate unexpected errors
                $self->{RC}     = NIME_EXPIRED;
                $self->emit('log',"nimNamedRequest timeout\n");
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
    elsif(defined $self->{port} && defined $self->{robot}) {
        $self->emit('log',"nimRequest triggered\n");
        for(;$i < $self->{retry};$i++) {
            eval {
                local $SIG{ALRM} = sub { die "alarm\n" }; 
                alarm $timeout;
                ($RC,$Ret) = nimRequest(
                    $self->{robot},
                    $self->{port},
                    $self->{callback},
                    $PDS->data
                );
                alarm 0;
            };
            if ($@) {
                die unless $@ eq "alarm\n";   # propagate unexpected errors
                $self->{RC}     = NIME_EXPIRED;
                $self->emit('log',"nimRequest timeout\n");
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
    else {
        $self->emit('log',"missing request data to launch a new request!\n");
    }
    $self->emit('done',$RC);
    return $RC;
}

1;
