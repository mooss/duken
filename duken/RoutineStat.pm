package duken::RoutineStat;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;
use constant
{
    CONSTRUCTOR => 0,
    METHOD => 1,
    FUNCTION => 2,
};

my $methodRegex = '(.*?)(<.*>)?::(.*)\((.*)\)( const)?';
my $functionRegex = '(.*)\((.*)\)';

#TODO: recoder avec de l'héritage

sub new
{
    my ($class) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    return $this;
}


sub build
{
    my ($class, $signature, $id) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    $this->{id} = $id;

    if($signature =~ m/$methodRegex/)
    {
        
        $this->{class} = $1;
        $this->{templateParameter} = (defined($2)) ? $2 : "";
        if($1 ne $3)#methode
        {
            $this->{name} = $3;
            $this->{routineType} = METHOD;
        }
        else#constructeur
        {
            $this->{routineType} = CONSTRUCTOR;
        }

        $this->{args} = $4;
        $this->{constIndicator} = (defined($5)) ? $5 : "";

        return $this;
    }
    elsif($signature =~ m/$functionRegex/)
    {
        $this->{name} = $1;
        $this->{args} = $2;
        $this->{routineType} = FUNCTION;
        return $this;
    }
    elsif($signature =~ m/main/)
    {
        $this->{name} = "main";
        $this->{args} = "";
        $this->{routineType} = FUNCTION;
        return $this;
    }
    return undef;
}

sub id
{
    my $this = shift;
    return $this->{id};
}

sub isConstructor
{
    my $this = shift;
    return $this->{routineType} == CONSTRUCTOR;
}

sub setPrefix()
{
    my ($this, $pre) = @_;
    $this->{prefix} = $pre;
}

sub setSuffix()
{
    my ($this, $suf) = @_;
    $this->{suffix} = $suf;
}

sub rawString
{
    my $this = shift;

    my $result;
    if($this->{routineType} == CONSTRUCTOR)
    {
        $result = $this->{class} . $this->{templateParameter} . "::" . $this->{class} . "($this->{args})";
    }
    elsif($this->{routineType} == METHOD)
    {
        $result = $this->{class} . $this->{templateParameter} . "::" . $this->{name} . "($this->{args})" . $this->{constIndicator};
    }
    elsif($this->{routineType} == FUNCTION)
    {
        $result = $this->{name} . "($this->{args})";
    }

    return $result;#reference, maybe ?
    
}

sub toString
{
    my $this = shift;

    my $result;
    $result .= $this->{prefix} if(defined $this->{prefix});
    $result .= $this->rawString();
    $result .= $this->{suffix} if(defined $this->{suffix});
    return $result;
}
1;
