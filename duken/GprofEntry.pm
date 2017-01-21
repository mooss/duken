package duken::GprofEntry;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

use duken::CallStat;

sub new
{
    
    my ($class) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    $this->{index} = -1;
    $this->{time} = -1;
    $this->{self} = -1;
    $this->{children} = -1;
    $this->{callNumber} = -1;
    $this->{signature} = -1;
    $this->{incoming} = [];
    $this->{outgoing} = [];
    
    return $this;
}

sub addIncoming
{
    my ($this, $self, $children, $callNumber, $index) = @_;
    push(@{$this->{incoming}}, duken::CallStat->new($self, $children, $callNumber, $index) );
}

sub addOutgoing
{
    my ($this, $self, $children, $callNumber, $index) = @_;
    push(@{$this->{outgoing}}, duken::CallStat->new($self, $children, $callNumber, $index) );
}

sub id
{
    my $this = shift;
    return $this->{index} -1;
}

1;
