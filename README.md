# perluim5
CA UIM (Nimsoft) Perl Object-Oriented framework. Version 5 of perluim series.

# Roadmap (alpha stage)

- New request object (with Response object).
- New probe object (to replace default server solution with proper events catching).
- New logger class (updated from v4.2) 
- Built-in event class.
- Re-implementation of useful class of V4 into the Addons namespace.
- New probes abstraction layer (**work in progress**)

## Request (alpha release)

The new request object offer a proper Object-oriented API. Launch multiple request without re-creating any objects, store response object and get more data about it.

```perl
my $Logger = Perluim::Logger->new({
    file => "test.log",
    level => 6
});

my $req = uimRequest({
    robot => "serverName", 
    port => 48000, 
    callback => "probe_list",
    retry => 3,
    timeout => 2
});

$Logger->trace( $req );

$req->on( done => sub {
    my $RC = shift;
    if($RC == NIME_OK) {
        $Logger->success("Request OK");
        my $data = $req->getData(); 
        $Logger->debug(Dumper( $data ));
        return;
    }
    $Logger->error("request fail with RC => $req->{RC}");
});

my @Probes = ('controller','distsrv');
$req->send(0,{ name => $_ }) for @Probes;
```

Example with Response object (returned by send).

```perl
sub getLocalRobot {
    my ($options) = @_; 
    $options = assignHash({ addr => "controller", callback => "get_info" },$options,$IDefaultRequest);
    my $req = uimRequest($options);
    $Logger->trace($req) if defined $Logger && $Debug == 1;
    my $res = $req->send(1);
    return $res->rc(), $res->is(NIME_OK) ? Perluim::Probes::Robot->new($res->pdsData()) : undef;
}
```

## Response (draft)

Returned by the Request.

**To be integrated**
- More informations about : callback,addr,numbers of retry before success etc..

```perl
my $Response = $req->send(0); 
$Response->rc(); 
$Response->is(NIME_ERR); 
$Response->pdsData(); 
$Response->hashData(); 
```

## Events (alpha release)

```perl
use Perluim::Core::Events;

my $Emitter = Perluim::Core::Events->new;

$Emitter->on(foo => sub {
    print "hello world! \n";
});

$Emitter->on(foo => sub {
    print "hello world 2! \n";
});

$Emitter->emit('foo'); # stdout hello world! and hello world 2!
```

## Logger (alpha release) 

**To be integrated**
- Truncate support (chunk)
- Pipe to another fileHandler

```perl
my $Logger = Perluim::Logger->new({
    file => "test.log",
    level => 6
});
```

## Probe (alpha release)

**To be integrated**
- Scheduled callback
- Integrated infrastructure scan
- Test around hubpost and subscribe

```perl
my $probe = uimProbe({
    name => "test",
    version => "1.0",
    timeout => toMilliseconds(10)
});

$Logger->trace( $probe );

$probe->registerCallback( "get_info" , {
    name => "String",
    count => "Int"
});

$probe->on( restart => sub {
    $Logger->info("Probe restarted");
});

$probe->on( timeout => sub {
    $Logger->info("Probe timeout");
});

$probe->start();

sub get_info {
    my ($hMsg,$count,$name) = @_;
    $Logger->info("get_info callback triggered with count => $count and name => $name");
    nimSendReply($hMsg);
}
```

## Probes 

> Work in progress

## Others

- Extend all class by an Event instance.
- Extend probe by an abstracted class with default callback (_restart etc..)
