# perluim5
CA UIM (Nimsoft) Perl Object-Oriented framework. Version 5 of perluim series.

# Roadmap (alpha stage)

- new Request object 
- new Probe Object (to replace old main.pm) 
- Rework Logger class.
- Integrated Emitter 
- new Server class 

## Request draft 

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
