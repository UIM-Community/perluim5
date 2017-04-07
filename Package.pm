package Perluim::Package;

use strict;
use warnings;

sub new {
    my ($class,$pds) = @_;
    my $this = {
        name            => $pds->get("name"),
        description     => $pds->get("description") || "",
        version         => $pds->get("version") || "",
        build           => $pds->get("build") || "",
        date            => $pds->get("date") || "",
        install_date    => $pds->get("install_date")
    };
    return bless($this,ref($class) || $class);
}

1;
