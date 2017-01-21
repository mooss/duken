package duken::ClassStat;
use strict;
use warnings;

sub new
{
    my ($class, $className) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    $this->{NAME} = $className;
    $this->{METHODS} = [];
    
}

sub addMethod
{
    my ($this, )
}

1;
