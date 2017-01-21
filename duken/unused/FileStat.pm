package duken::FileStat;


use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

sub new
{
    my ($class) = @_;
    $class = ref($class) || $class;

    my $this = {};
    bless($this, $class);
}
