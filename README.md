# perluim5
CA UIM (Nimsoft) Perl Object-Oriented framework. Version 5 of perluim series.

# Roadmap (alpha stage)

- new Request object (**final tests**)
- new Probe Object (server class)
- Rework Logger class.
- Integrated Emitter with automatic mapping.
- re-implementation of V4.x addons (with renaming) into Addons namespace
- Create hub and controller probes class.

## Request (v1.0) 

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

## Emitter draft 

**To be integrated** 
- Once method 

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

## Logger draft 

**To be integrated**
- Timezone 
- Truncate review
- Multiple pipeline 
- Remove cleanLogs (move to utils.pm)
- Crash security (write on disk).

```perl
my $Logger = Perluim::Logger->new({
    file => "test.log",
    level => 6
});
```

## Probe draft (server class)

**To be integrated**
- Scheduled callback
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

## Others

- Simplify request construction in core class ( Merge hash, Default interfaces etc.. ) 
- Add a binding for eventEmitter (simple extending ..)
