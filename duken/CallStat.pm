package duken::CallStat;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

sub new
{
    
    my ($class, $self, $children, $callNumber, $index) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);
    $this->{self} = $self;
    $this->{children} = $children;
    $this->{callNumber} = $callNumber;
    $this->{index} = $index;

    return $this;
}

sub id
{
    my $this = shift;
    return $this->{index} -1;
}

1;
