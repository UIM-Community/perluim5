package Perluim::Core::Request;

use Nimbus::API;
use Nimbus::PDS;
use Data::Dumper;
use Perluim::Core::Events;

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
    my ($self,$timeMilli) = @_;
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
    $self->emit('log','inner data is not defined!');
    return undef;
}

sub send {
    my ($self,$callRef,$PDSData) = @_;
    my $overbus = defined $callRef->{overbus} ? $callRef->{overbus} : 1;
    my $PDS     = $PDSData || Nimbus::PDS->new;
    my $i       = 0;
    my $RC      = NIME_ERROR;
    my $Ret     = undef;

    $| = 1; # Auto-flush ! 

    if($overbus) {
        $self->emit('log','nimNamedRequest triggered');
        for(;$i < $self->{retry};$i++) {
            ($RC,$Ret) = nimNamedRequest(
                $self->{addr},
                $self->{callback},
                $PDS->data
            );
            $self->{Ret}    = $Ret;
            $self->{RC}     = $RC;

            last if $RC == NIME_OK;
            sleep(1);
        }
    }
    else {
        $self->emit('log','nimRequest triggered');
        for(;$i < $self->{retry};$i++) {
            ($RC,$Ret) = nimRequest(
                $self->{robot},
                $self->{port},
                $self->{callback},
                $PDS->data
            );
            $self->{Ret}    = $Ret;
            $self->{RC}     = $RC;

            last if $RC == NIME_OK;
            sleep(1);
        }
    }
    return $RC;
}

1;
