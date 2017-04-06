# perluim5
CA UIM (Nimsoft) Perl Object-Oriented framework. Version 5 of perluim series.

# Roadmap (alpha stage)

- new Request object (**final tests**)
- new Probe Object (server class)
- Rework Logger class.
- Integrated Emitter with automatic mapping.
- re-implementation of V4.x addons (with renaming) into Addons namespace
- Create hub and controller probes class.

## Request draft 

**To be integrated** 
- PDS auto-parsing (in and out). 

```perl
my $req = uimRequest({
    robot => "s00v09927022",
    port => 48000,
    callback => "get_info"
});

$req->on(log => sub {
    my $msg = shift; 
    print "request log => $msg \n";
});

if( $req->send({overbus => 0}) == NIME_OK ) {
    print "request ok! \n";
    my $data = $req->getData(); 
    print Dumper( $data )."\n";
}
else {
    print "request fail with RC => $req->{RC} \n";
}
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
