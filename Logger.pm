package Perluim::Logger;
use strict;
use warnings;
use File::Copy;
use File::stat;
use File::Path 'rmtree';
use IO::Handle;
use Data::Dumper;
use Scalar::Util qw(looks_like_number);

our %loglevel = (
	0 => "[CRITICAL]",
	1 => "[ERROR]   ",
	2 => "[WARNING] ",
	3 => "[INFO]    ",
	4 => "[DEBUG]   ",
	5 => "          ",
	6 => "[SUCCESS] "
);

sub new {
    my ($class,$argRef) = @_;
    my $this = {
        file 	=> $argRef->{file},
        level 	=> defined $argRef->{level} 	? $argRef->{level} : 3,
        size 	=> defined $argRef->{size} 		? $argRef->{size} : 0,
        rewrite => defined $argRef->{rewrite} 	? $argRef->{rewrite} : "yes",
		_header => "",
		_symbol => undef,
        _time 	=> time(),
        _fh 	=> undef
    };
    my $blessed = bless($this,ref($class) || $class);
	$blessed->{_symbol} = $blessed->{rewrite} eq "yes" ? ">" : ">>";
	$blessed->truncate() if $blessed->{size} != 0;
	open($blessed->{_fh}, $blessed->{_symbol} ,$blessed->{file});
	$blessed->nolevel("New console class created with logfile as => $argRef->{file}!");
	return $blessed;
}

sub setLevel {
	my ($self,$level) = @_; 
	if(defined $level && looks_like_number($level)) {
		$self->{level} = $level;
	}
}

sub setHeader {
	my ($self,$headerStr,$reset) = @_;
	if(!defined $headerStr) {
		return;
	}
	$reset = defined $reset ? $reset : 1;
	if($reset) {
		$self->{_header} = $headerStr;
	}
	else {
		$self->{_header} .= $headerStr;
	}
}

sub resetHeader {
	my ($self) = @_;
	$self->{_header} = "";
}

sub _date {
	my @months  = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
	my @days    = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
    my $timetwoDigits = sprintf("%02d %02d:%02d:%02d",$mday,$hour,$min,$sec);
	return "$months[$mon] $timetwoDigits";
}

sub trace {
    my($self,$emitter) = @_;
    eval {
        $emitter->on(log => sub {
            $self->info(shift);
        });
    };
    if($@) {
        # Do nothing!
    }
}

sub catch {
	my($self,$emitter) = @_;
    eval {
        $emitter->on(error => sub {
            $self->error(shift);
        });
    };
    if($@) {
        # Do nothing!
    }
}

sub dump {
	my($self,$ref) = @_;
    eval {
		my @Hash = $ref->dump();
        $self->nolevel(Dumper(\@Hash));
    };
    if($@) {
        $self->warn($@);
    }
}

sub truncate {
	my ($self,$size) = @_;
	truncate($self->{_fh},defined $size ? $size : $self->{size});
}

sub finalTime {
	my ($self) = @_;
	my $FINAL_TIME  = sprintf("%.2f", time() - $self->{_time});
    my $Minute      = sprintf("%.2f", $FINAL_TIME / 60);
	$self->log(5,'---------------------------------------');
    $self->log(5,"Execution time = $FINAL_TIME second(s) [$Minute minutes]!");
	$self->log(5,'---------------------------------------');
}

sub copyTo {
	my ($self,$path) = @_;
	copy("$self->{file}","$path/$self->{file}") or warn "Failed to copy logfile!";
}

sub log {
    my ($self,$level,$msg) = @_; 
    if(!defined($level)) {
        $level = 3;
    }
    if($level <= $self->{level} || $level >= 5) {
		my $date 		= _date();
		my $filehandler = $self->{_fh};
		my $header 		= $self->{_header};
		print $filehandler "$date $loglevel{$level} - ${header}${msg}\n";
		print "$date $loglevel{$level} - ${header}${msg}\n";
		$filehandler->autoflush;
    }
}

sub fatal {
	my ($self,$msg) = @_;
	$self->log(0,$msg);
}

sub error {
	my ($self,$msg) = @_;
	$self->log(1,$msg);
}

sub warn {
	my ($self,$msg) = @_;
	$self->log(2,$msg);
}

sub info {
	my ($self,$msg) = @_;
	$self->log(3,$msg);
}

sub debug {
	my ($self,$msg) = @_;
	$self->log(4,$msg);
}

sub nolevel {
	my ($self,$msg) = @_;
	$self->log(5,$msg);
}

sub success {
	my ($self,$msg) = @_;
	$self->log(6,$msg);
}
