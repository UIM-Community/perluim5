package Perluim::Core::Events;

sub new {
    my ($class) = @_;
    my $this = {
        subscribers => {}
    };
    return bless($this,ref($class) || $class);
}

sub on {
    my ($self,$eventName,$callbackRef) = @_;
    if($self->has_subscribers($eventName)) {
        push(@{ $self->{subscribers}->{$eventName} },$callbackRef);
    }
    else {
        my @Arr = ();
        push(@Arr,$callbackRef);
        $self->{subscribers}->{$eventName} = \@Arr;
    }
}

sub once {
    my ($self,$eventName,$callbackRef) = @_; 
}

sub emit {
    my ($self,$eventName,$data) = @_;
    $self->_exec($eventName,$data) if $self->has_subscribers($eventName);
}

sub _exec {
    my ($self,$subscriberName,$data) = @_; 
    foreach my $cb (@{ $self->{subscribers}->{$subscriberName} }) {
        $cb->($data);
    }
}

sub has_subscribers {
    my ($self,$subscriberName) = @_;
    return defined $self->{subscribers}->{$subscriberName} ? 1 : 0;
}

1;
