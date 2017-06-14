# perluim5
CA UIM (Nimsoft) Perl Object-Oriented framework. Version 5 of perluim series.

# Roadmap (alpha & draft stage)

- Load requests from CFG (like alarmsmanager.pm from V4.X).
- Try to handle request with async & threads module.
- Work to include a Promise API (async handle).

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

```perl
my $Response = $req->send(0); 
$Response->rc(); 
$Response->is(NIME_ERR); 
$Response->pdsData(); 
$Response->hashData(); 
$Response->dump(); 
$Response->getCallback();
etc...
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
- Header mech

```perl
my $Logger = Perluim::Logger->new({
    file => "test.log",
    level => 6
});
$Logger->log(LogWARN,"Warning !!!");
$Logger->warn("Warning 2!!!"); 
$Logger->debug("Debug info!"); 

$Logger->dump( $Response ); 
$Logger->catch( $Emitter );
$Logger->trace( $Emitter );
```

## Server API (alpha release)

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

## CFGManager (draft)

Safer and complete CFGManager with error & debugging handler. 

```perl
my $CFGManager = Perluim::Addons::CFGManager->new("ssr_backup.cfg",1);
$Logger->trace( $CFGManager );

$STR_Properties          = $CFGManager->read("setup","properties");
$STR_Login               = $CFGManager->read("setup","login","administrator");
$STR_Password            = $CFGManager->read("setup","password");
$STR_ExportDirectory     = $CFGManager->read("setup","export_directory","export");
```

To review: Undefined handler.
