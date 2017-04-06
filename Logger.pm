package Perluim::Logger;
use strict;
use warnings;
use File::Copy;
use File::stat;
use File::Path 'rmtree';
use IO::Handle;

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
        _time 	=> time(),
        _fh 	=> undef
    };
    my $blessed = bless($this,ref($class) || $class);
	my $rV = $blessed->{rewrite} eq "yes" ? ">" : ">>";
	if($blessed->{size} != 0) {
		my $fileSize = (stat $blessed->{file})[7];
		if($fileSize >= $blessed->{size}) {
			copy("$blessed->{file}","_$blessed->{file}") or warn "Failed to copy logfile!";
			$rV = ">";
		}
	}
	open ($this->{_fh},"$rV","$argRef->{file}");
	$blessed->log(5,"New console class created with logfile as => $argRef->{file}!");
	return $blessed;
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

sub truncate {
	my ($self) = @_;
	if($self->{size} != 0) {
		my $fileSize = (stat $self->{file})[7];
		if($fileSize >= $self->{size}) {
			copy("$self->{file}","_$self->{file}") or warn "Failed to copy logfile!";
			close($self->{_fh});
			open ($self->{_fh},">","$self->{file}");
		}
	}
}

sub cleanLogs {
	my ($self,$directory,$maxAge) = @_;

	opendir(DIR,"$directory");
	my @directory = readdir(DIR);
	my @removeDirectory = ();
	foreach my $file (@directory) {
		next if ($file =~ m/^\./);
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat("$directory/$file");
		if(defined $ctime) {
			push(@removeDirectory,$file) if(time() - $ctime > $maxAge);
		}
	}

	foreach(@removeDirectory) {
		$self->log(2,"Remove old directory $directory => $_");
		rmtree("$directory/$_");
	}
}

sub log {
    my ($self,$level,$msg) = @_; 
    if(not defined($level)) {
        $level = 3;
    }
    if($level <= $self->{level} || $level >= 5) {
		my $date = _date();
		my $filehandler = $self->{_fh};
		print $filehandler "$date $loglevel{$level} - $msg\n";
		print "$date $loglevel{$level} - $msg\n";
		$filehandler->autoflush;
    }
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
	copy("$self->{logfile}","$path/$self->{logfile}") or warn "Failed to copy logfile!";
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
