package duken::CallTree;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

use List::Util qw[max];

sub new
{
    my ($class, $routine) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    $this->{node} = $routine;
    $this->{leaves} = [];
    $this->{cycle} = FALSE;
    return $this;
    
}

sub addLeaf
{
    my ($this, $leaf) = @_;

    push(@{$this->{leaves}}, $leaf);
}

sub printTree
{
    my ($this, $depth) = @_;
    if(!defined($depth))
    {
        $depth = 0;
    }

    print "  " x $depth;
    say $this->{node}->toString() . ($this->{cycle} ? " cycle" : "");
    foreach (@{$this->{leaves}})
    {
        $_->printTree($depth +1);
    }
}

sub height
{
    my $this = shift;
    my $result = 0;
    foreach (@{$this->{leaves}})
    {
        $result = max ($result, $_->height() +1);
    }
    return $result;
}

sub numberOfNodes
{
    my $this = shift;
    my $result = 0;
    foreach(@{$this->{leaves}})
    {
        $result += $_->numberOfNodes();
    }
    return ++$result;
}

1;
