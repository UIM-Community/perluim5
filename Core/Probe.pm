package Perluim::Core::Probe;

sub new {
    my ($class,$argRef) = @_;
    my $this = {
        name => $argRef->{name},
        version => defined $argRef->{version} ? $argRef->{version} : "1.0"
    };
    return bless($this,ref($class) || $class);
}

1;
