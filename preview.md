## Request API

The new request object offer a proper Object-oriented API. Launch multiple request without re-creating any object or schema, store response object and get more data about it and how the execution has been done. This API now include a timeout support on UNIX system and a embedded retry mechanism to simplify your high level code.

All request has been fully integrated with the new event emitter to catch and trace every actions and errors perfectly. We are working a asynchronous version of the API (to be handled in the same way with the event "done").

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

## Response Object

Returned by the Request. The response Object store all informations about the request work and let you retrieve the data like you want by managing the PDS Object for you.

```perl
my $Response = $req->send(0); 
$Response->rc();
$Response->pdsData(); 
$Response->hashData(); 
$Response->dump(); 
$Response->getCallback();
etc...
```

```perl
if($Response->rc(NIME_OK)) {
    $Logger->info("IS OK!");
}
```

## Events

A classical event emitter. 

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

## Logger (nimLog object oriented)

nimLog object-oriented implementation with advanced debugging tools for core API.

```perl
my $Logger = Perluim::Logger->new({
    file => "test.log",
    level => 5
});
$Logger->log(LogWARN,"Warning !!!");
$Logger->warn("Warning 2!!!"); 
$Logger->debug("Debug info!"); 

$Logger->dump( $Response ); 
$Logger->catch( $Emitter );
$Logger->trace( $Emitter );
```

## Probe API 

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
