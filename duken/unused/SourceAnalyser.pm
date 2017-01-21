package duken::SourceAnalyser;
use strict;
use warnings;

sub new
{
    my ($class, @files) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);
    
    this->{SOURCES} = @files;
    this->{MOTHER_CLASSES} = [];
    
    
    return $this;
}

sub buildStat
{
    foreach(this->{SOURCES})
    {
        
    }
    
}

1;
