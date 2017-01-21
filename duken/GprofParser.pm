package duken::GprofParser;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

#use Data::Dumper;
use duken::GprofEntry;
use duken::RoutineStat;
use duken::CallTree;

sub new
{
    
    my ($class, $gprofFile) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    $this->{entries} = [];
    $this->{input} = $gprofFile;

    return $this;
}

sub parse
{
    my $this = shift;

    open my $handler, '<',  $this->{input} or die "impossible d'ouvrir $this->{input}";
    goToCallgraph($handler) or die "$this->{input} does not appear to be a gprof output";
    my $nextline = <$handler>;
    while($this->analyseSection($handler))
    {}


    close $handler;
}

sub goToCallgraph
{
    my $fh = shift;

    my $found = FALSE;
    while(my $line = <$fh>)#lecture de l'entrée
    {
        chomp($line);
        if($line =~ m/index\s+%\s+time\s+self\s+children\s+called\s+name/)
        {
            $found = TRUE;
            last;
        }
    }
    return $found;
}

#TODO : séparer l'analyse en subroutines (clarté)
sub analyseSection
{
    my ($this, $fh) = @_;

    my $indexReached = FALSE;
    my $lineRegex = '^\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)\/\d+\s+.+ \[(\d+)\]';
    my $indexRegex = '^\[(\d+)\]\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+\.\d+)\s+(\d+)?\s+(.+) \[\d+\]';

    my $entry = duken::GprofEntry->new();
    
    my $line = <$fh>;
    if($line eq "\n")
    {
        return FALSE;
    }
    elsif($line =~ m/<spontaneous>/)
    {
        $line = <$fh>;
    }

    do
    {
        chomp $line;
        if($line =~ m/^-+$/)
        {
            if(!$indexReached)
            {
                say STDERR "analyse terminée sans touver de sujet";
            }
            push(@{$this->{entries}}, $entry);
            
            return TRUE;
        }

        if(!$indexReached)
        {
            if($line =~ m/$indexRegex/)
            {
                #                print "sujet trouvé : $1 ; $2 ; $3 ; $4 ; ";
                $entry->{whole_line} = $&;
                $entry->{index} = $1;
                $entry->{time} = $2;
                $entry->{self} = $3;
                $entry->{children} = $4;
                if(defined($5))
                {
                    $entry->{callNumber} = $5;                    
                }
                else
                {
                    $entry->{callNumber} = 0;
                }

                $entry->{signature} = $6;
                
                $indexReached = TRUE;
            }
            elsif($line =~ m/$lineRegex/)
            {
                #say "appellant trouvé : $1 ; $2 ; $3 $4";
                $entry->addIncoming($1, $2, $3, $4);
            }
            else
            {
                say STDERR "ligne appellée non matchée : $line";
            }
        }
        else#$indexReached
        {
            if($line =~ m/$lineRegex/)
            {
                #say "appellé trouvé : $1 ; $2 ; $3 $4";
                $entry->addOutgoing($1, $2, $3, $4);
            }
            else
            {
                say STDERR "ligne appelante non matchée : $line";
            }
        }

    } while($line = <$fh>);

    die "erreur lors de l'analyse"
    
}

sub checkOrder
{
    my $this = shift;
    #say "checking order...";
    my $outOfPlace = $this->findOutOfPlace();
    if($outOfPlace == -1)
    {
        #say "everything is in order"
    }
    else
    {
        die "orders of functions not respected : [$outOfPlace]";
        #$this->printIndexAndId();
        #$this->printWholeLines();
    }
    
}

sub findOutOfPlace
{
    my $this = shift;
    for(my $i = 0; $i < @{$this->{entries}}; ++$i)
    {
        if($this->{entries}->[$i]->{index} != $i +1)
        {
            print STDERR "error : $this->{entries}->[$i]->{signature} ; ";
            return $i;
        }
    }
    return -1;
}

sub selectRoutines
{
    my ($this, $filtre) = @_;

    my $nbEntries = @{$this->{entries}};
    my $result = [];

    for(my $i = 0; $i < $nbEntries; ++$i)
    {
        my $routine = &$filtre($this->{entries}->[$i]->{signature}, $i);
        if(defined($routine))
        {
            push(@$result, $routine);
        }
    }

    return $result;
}

sub getRoutines
{
    my $this = shift;
    
    my $useless = duken::RoutineStat->new();
    my $mref = sub { $useless->build(@_) };# ><'
    
    return $this->selectRoutines($mref);
}

sub isSpontaneous
{
    my ($this, $id) = @_;

    return @{$this->{entries}[$id]{incoming}} == 0 && $id != 0;
}


sub isOnlyCalledBySpontaneous
{
    my ($this, $id) = @_;

    foreach(@{$this->in($id)})
    {
        #print Dumper $_;
        if(!$this->isSpontaneous($_->{index} -1) && !$this->isOnlyCalledBySpontaneous($_->{index} -1) || $_->{index} == 1)
        {
            return FALSE;
        }
    }
    #say $this->{entries}->[$id]->{signature} . " : true";
    return TRUE;
}

sub growTree
{
    my ($this, $rootine, @functionIdList) = @_;

    @functionIdList = () if(!defined($functionIdList[0]));
    
    my $id = $rootine->{id};
    push @functionIdList, $id;
    my $root = duken::CallTree->new($rootine);
    foreach (@{$this->out($id)})
    {
        my $outId = $_->id();
        if( !grep { $_ == $outId } @functionIdList)#test if the function is not already in the callTree
        {
            $root->addLeaf($this->growTree(duken::RoutineStat->build($this->sign($outId), $outId ), @functionIdList));
        }
        else
        {
            my $leaf = duken::CallTree->new(duken::RoutineStat->build($this->sign($outId), $outId ));
            $leaf->{cycle} = TRUE;
            $root->addLeaf($leaf);
        }
    }
    return $root;
}

sub getCallList
{
    my ($this, $id, $result) = @_;
    
    $result = [] if(!defined($result));

    push @$result, $id;
    foreach(@{$this->out($id)})
    {
        my $outId = $_->id();
        $this->getCallList($outId, $result) if(!grep {$_ == $outId} @$result);
    }
    return $result;
}

sub getCallListAsOne#chimique
{
    my ($this, $ids, $result) = @_;
    
    $result = [] if(!defined($result));
    my $id = shift @$ids;
    if(defined($id))
    {
        push @$result, $id;
        foreach(@{$this->out($id)})
        {
            my $outId = $_->id();
            $this->getCallList($outId, $result) if(!grep {$_ == $outId} @$result);
        }
        $this->getCallListAsOne($ids, $result);
    }
    return $result;
}

sub growSpontCallTree
{
    my ($this, $rootine) = @_;
    
    my $id = $rootine->{id};
    my $root = duken::CallTree->new($rootine);
    foreach(@{$this->out($id)})
    {
        if($this->isOnlyCalledBySpontaneous($_->id()))
        {
            $root->addLeaf($this->growSpontCallTree(duken::RoutineStat->build($this->sign($_->id()), $_->id())));
        }
    }
    return $root;
}

sub growUnusedCallTree#regrouper avec growSpontCallTree en utilisant une reference
{
    my ($this, $rootine) = @_;
    
    my $id = $rootine->{id};
    my $root = duken::CallTree->new($rootine);
    foreach(@{$this->out($id)})
    {
        if($this->callnb($_->id()) == 0)
        {
            $root->addLeaf($this->growUnusedCallTree(duken::RoutineStat->build($this->sign($_->id()), $_->id())));
        }
    }
    return $root;
}


sub out
{
    my ($this, $id) = @_;
    return $this->{entries}[$id]{outgoing};
}

sub in
{
    my ($this, $id) = @_;
    return $this->{entries}[$id]{incoming};
}

sub sign
{
    my ($this, $id) = @_;
    return $this->{entries}[$id]{signature};
}

sub callnb
{
    my ($this, $id) = @_;
    return $this->{entries}[$id]{callNumber};
}

sub getIncomingSignatures
{
    my ($this, $id) = @_;
    my $result = [];

    foreach(@{$this->in($id)})
    {
        push @$result, $this->sign($_->id());
    }
    return $result;
}

1;
