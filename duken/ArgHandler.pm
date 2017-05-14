package duken::ArgHandler;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

use duken::GprofParser;
#use Data::Dumper;

my $_blank_match = '^~$';
my $_incoming_replace = '~i';
my $_outgoing_replace = '~o';
my $_callnumber_replace = '~c';
my $_incoming_list_replace = '~inclist';

my $generalSelection =
    { "spont"       	=> [qw(--spontaneous -S)],
      "spontCalled" 	=> [qw(--called-by-spontaneous -C)],
      "all" 		=> [qw(--all)] };

my $specificSelection =
    { "signature"	=> [qw(--signature -s)],
      "constructors"    => [qw(--constructors -c)] };

my $selectionTransformation = { 
    "optTree" 		=> {
        "spontCallTree"		=> [qw(--spontaneous-calltree -V)],
        "unusedCallTree"	=> [qw(--unused-calltree -U)],
        "fullCallTree"		=> [qw(--calltree -T)] },
    "optCallList" 	=> {
        "callList"		=> [qw(--calllist)],
        "outCallList"		=> [qw(--out-of-calllist)] },
};

my $callListTransformation =
    { "optCallListAsOne"	=> [qw(--calllist-as-one)] };


my $treeSort =
    { "heightSort"	=> [qw(--heightsort -d)],
      "nodeSort"	=> [qw(--nodesort -n)] };

my $plainSort =
    { "incoming"	=> [qw(--incoming -i)],
      "outgoing"	=> [qw(--outgoing -o)],
      "callnumber" 	=> [qw(--callnumber -a)] };

my $treeSelection =
    { "minHeight"	=> [qw(--min-height)],
      "minNodes"	=> [qw(--min-node-number)],
      "maxHeight"	=> [qw(--max-height)],
      "maxNodes"	=> [qw(--max-node-number)] };

my $outputFormatting =
    { "linePrefix"	=> [qw(--before -B)],
      "lineSuffix" 	=> [qw(--after -A)]};

my $cols = 15;
my $roof = "=" x $cols;
my $begin = ">" x $cols;
my $end = "<" x $cols;

my $shortcuts = [
    { "shortcut" 	=> [qw(--nice-shortcut)],
      "replacement" 	=> ["--before", "\n\n$roof\n$_incoming_list_replace\n$begin\ncalled $_callnumber_replace times\n", "--after", "\n$end" ] }
];


sub new
{
    my ($class, $args) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);
    expandGroupedOptions($args);
    expandShortcuts($args);

    while(defined(my $arg = shift @$args))
    {
        if( !($this->uniqueOption($arg, $generalSelection, "optGeneral") ||
              $this->specificSelection($arg, $args) ||
              $this->uniqueNestedOption($arg, $selectionTransformation, "optSelectionTransformation") ||
              $this->uniqueOption($arg, $treeSort, "optTreeSort") ||
              $this->uniqueOption($arg, $plainSort, "optPlainSort") ||
              $this->combinableOption($arg, $treeSelection, 1, $args) ||
              $this->combinableOption($arg, $outputFormatting, 1, $args) ||
              $this->combinableOption($arg, $callListTransformation) ))
        {
            if(defined($this->{file}))
            {
                die "unrecognized option : $arg";
            }
            $this->{file} = $arg;
        }
    }

    $this->applyDefault();
    $this->checkForIncoherences();

    return $this;
}

sub expandGroupedOptions
{
    my $args = shift;
    for( my $i = 0; $i < @$args; ++$i)
    {
        if($args->[$i] =~ m/^-(\w{2,}$)/)
        {
            #say "expansion de $args->[$i]";
            my $opts = $1;
            splice @$args, $i, 1;
            --$i;
            for(my $j = 0; $j < length $opts; ++$j)
            {
                splice(@$args, $i+1, 0, "-" . substr($opts, $j, 1));
                ++$i;
            }
        }
    }
}

sub expandShortcuts
{
    my $args = shift;

    for( my $i = 0; $i < @$args; ++$i){
        foreach my $expansion (@$shortcuts){
            if(grep {$_ eq $args->[$i]} @{$expansion->{shortcut}})
            {
                splice @$args, $i, 1, @{$expansion->{replacement}};
                --$i;
            }
        }
    }

}

sub checkForIncoherences
{
    my $this = shift;
    
    if(defined($this->{optTreeSort}) && !defined($this->{optTree}))
    { say STDERR "warning : sort option for tree activated but no tree option activated"; }
    
    if(!defined($this->{optTree}) &&
        ( defined($this->{minNodes}) ||
          defined($this->{minHeight}) ||
          defined($this->{maxNodes}) ||
          defined($this->{maxHeight}) ))
    { say STDERR "warning : selection option for tree activated but no tree option activated"; }

    if(defined($this->{optCallListAsOne}) && !defined($this->{optCallList}))
    {
        say STDERR "warning : transformation for calllist activated but no calllist option activated";
    }

    if(!defined($this->{file}))
    {
        die "no input specified";
    }
}


sub applyDefault#peut mieux faire
{
    my $this = shift;
    if(!defined($this->{optGeneral}))
    {
        $this->{optGeneral} = "all";
    }
    if(defined($this->{optCallListAsOne}) && defined($this->{optCallList}))
    {
        $this->{linePrefix} = "" if !defined($this->{linePrefix});
        $this->{lineSuffix} = "" if !defined($this->{lineSuffix});
    }
}

sub specificSelection
{
    my ($this, $arg, $args) = @_;

    foreach my $name (keys %$specificSelection)
    {
        if( grep /^$arg$/, @{$specificSelection->{$name}})
        {
            !defined($this->{$name}) or die "repetition of option $arg";

            if($name eq "signature")
            {
                $this->{signature} = shift @$args or die "please specify pattern after $arg";
            }
            else
            {
                $this->{$name} = TRUE;
            }

            return TRUE;
        }
    }

    return FALSE;
}

sub combinableOption
{
    my ($this, $arg, $hashRef, $additionnalArgs, $args) = @_;

    foreach my $name (keys %$hashRef)
    {
        if( grep /^$arg$/, @{$hashRef->{$name}})
        {
            !defined($this->{$name}) or die "repetition of option $arg";

            if(defined($additionnalArgs))
            {
                $this->{$name} = splice( @$args, 0, $additionnalArgs) or die "please specify additionnal argument after $arg";
            }
            else
            {
                $this->{$name} = TRUE;
            }

            return TRUE;
        }
    }

    return FALSE;
}


sub uniqueOption
{
    my ($this, $arg, $hashRef, $optName) = @_;
    foreach my $name (keys %$hashRef)
    {
        if(grep /^$arg$/, @{$hashRef->{$name}})
        {
            if(defined($this->{$optName}))
            {
                my $message = hashResume($hashRef);
                die "you can use only one of the following options :\n$message";
            }
            $this->{$optName} = $name;
            return TRUE;
        }
    }
    return FALSE;
}

sub uniqueNestedOption
{
    my ($this, $arg, $nestedHashRef, $metaName) = @_;
    foreach my $optName (keys %$nestedHashRef)
    {
        foreach my $instanceName (keys %{$nestedHashRef->{$optName}})
        {
            if(grep /^$arg$/, @{$nestedHashRef->{$optName}{$instanceName}})
            {
                if(defined($this->{$metaName}))
                {
                    my $message = nestedHashResume($nestedHashRef);
                    die "you can use only one of the following options :\n$message";
                }
                $this->{$metaName} = $optName;      
                $this->{$optName} = $instanceName;
                return TRUE;
            }
        }
    }
    return FALSE;
}

sub do
{
    my $this = shift;
    
    $this->{parser} = duken::GprofParser->new($this->{file});
    my $parser = $this->{parser};
    $parser->parse();
    $parser->checkOrder();

    $this->{routines} = $parser->getRoutines();
    @{$this->{selection}} = @{$this->{routines}};#not so sure about that
    
    $this->applyGeneralSelection();
    $this->applyFilter();

    $this->applyPlainSort();
    
    $this->printOutput();
}

sub applyGeneralSelection
{
    my $this = shift;
    
    if($this->{optGeneral} eq "spont")
    {
        @{$this->{selection}} = grep {$this->{parser}->isSpontaneous($_->{id})} @{$this->{selection}};
    }elsif($this->{optGeneral} eq "spontCalled")
    {
        @{$this->{selection}} = grep {$this->{parser}->isOnlyCalledBySpontaneous($_->{id})} @{$this->{selection}};
        
    }
}

sub applyFilter
{
    my $this = shift;

    if($this->{constructors})
    {
        @{$this->{selection}} = grep {$_->isConstructor() } @{$this->{selection}};
    }
    if($this->{signature})
    {
        @{$this->{selection}} = grep {$_->toString() =~ m/$this->{signature}/} @{$this->{selection}};
    }
}

sub applyPlainSort
{
    my $this = shift;

    if(defined($this->{optPlainSort}))
    {
        if($this->{optPlainSort} eq "incoming")
        {
            @{$this->{selection}} = sort { @{$this->{parser}->in($b->{id})} <=> @{$this->{parser}->in($a->{id})} } @$this->{selection};
        }
        if($this->{optPlainSort} eq "outgoing")
        {
            @{$this->{selection}} = sort { @{$this->{parser}->out($b->{id})} <=> @{$this->{parser}->out($a->{id})} } @{$this->{selection}};
        }
        if($this->{optPlainSort} eq "callnumber")
        {
            @{$this->{selection}} = sort { $this->{parser}->callnb($b->{id}) <=> $this->{parser}->callnb($a->{id}) } @{$this->{selection}};
        }

    }
}

sub printOutput#TODO: homogenéiser l'affichage entre tree, calllist et plain
{
    my $this = shift;
    
    if(defined($this->{optTree}))
    {
        $this->growTrees();
        $this->applyTreeSelection();
        $this->applyTreeSort();
        $this->refreshSelection();

        $this->buildLinePrefixes();
        $this->buildLineSuffixes();
        my $size = @{$this->{trees}};
        for( my $i = 0; $i < $size; ++$i)
        {
            print $this->{prefixes}[$i];
            $this->{trees}[$i]->printTree();
            print $this->{suffixes}[$i];
        }
    }
    elsif(defined($this->{optCallList}))
    {
        if(defined($this->{optCallListAsOne}))
        {
            $this->buildCallListAsOne();
            
            $this->buildLinePrefixes();
            $this->buildLineSuffixes();
            my $size = @{$this->{selection}};
            for( my $i = 0; $i < $size; ++$i)
            {
                print $this->{prefixes}[$i];
                say $this->{selection}[$i]->toString();
                print $this->{suffixes}[$i];
            }
            foreach(@{$this->{callListAsOne}})
            {
                say "\t" . $_;
            }
            
        }
        else
        {
            $this->buildCallLists();
            
            $this->buildLinePrefixes();
            $this->buildLineSuffixes();
            my $size = @{$this->{selection}};
            for( my $i = 0; $i < $size; ++$i)
            {
                print $this->{prefixes}[$i];
                say "";#$this->{selection}[$i]->toString();
                foreach (@{$this->{callLists}[$i]})
                {
                    say "\t" . $_;
                }
                print $this->{suffixes}[$i];
            }
        }
    }
    else
    {
        
        $this->buildLinePrefixes();
        $this->buildLineSuffixes();
        my $size = @{$this->{selection}};
        for( my $i = 0; $i < $size; ++$i)
        {
            print $this->{prefixes}[$i];
            print $this->{selection}[$i]->toString();
            print $this->{suffixes}[$i];
            say "";
        }
    }

    say "";
}

sub refreshSelection
{
    my $this = shift;
    @{$this->{selection}} = map {$_->{node}} @{$this->{trees}};
}
sub growTrees
{
    my $this = shift;
    
    if($this->{optTree} eq "spontCallTree")
    {
        @{$this->{trees}} = map {$this->{parser}->growSpontCallTree($_)} @{$this->{selection}};
        
    }
    elsif($this->{optTree} eq "unusedCallTree")
    {
        @{$this->{trees}} = map {$this->{parser}->growUnusedCallTree($_)} @{$this->{selection}};
    }
    elsif($this->{optTree} eq "fullCallTree")
    {
        @{$this->{trees}} = map {$this->{parser}->growTree($_)} @{$this->{selection}};
    }
    else
    {
        die "unexpected tree growth option : $this->{optTree}";
    }

}

sub buildCallLists#horreur sans nom. À recoder.
{
    my $this = shift;
    $this->{callLists} = [];
    my $clistRef = $this->{callLists};
    foreach my $routine (@{$this->{selection}})
    {
        push @$clistRef, $this->{parser}->getCallList($routine->id());
    }
    
    if($this->{optCallList} eq "outCallList")
    {
        for(my $j = 0; $j < @$clistRef; ++$j)#trop obscur (complemente la liste d'appel)
        {
            @{$clistRef->[$j]} = sort { $a <=> $b} @{$clistRef->[$j]};
            my $newlist = [0..$clistRef->[$j][0]-1];
            my $size = @{$clistRef->[$j]};
            my $i;
            for($i = 0; $i < $size; ++$i)
            {
                push @$newlist, ($clistRef->[$j][$i-1]+1 .. $clistRef->[$j][$i] -1);
            }
            push @$newlist, ($clistRef->[$j][$i-1]+1 .. @{$this->{parser}->{entries}} -1);#risky
            $clistRef->[$j] = $newlist;
        }
    }
    elsif($this->{optCallList} ne "callList")
    {
        die "unexpected callList option : $this->{optCallList}"
    }
    my $size = @$clistRef;
    for(my $i = 0; $i < $size ; ++$i)
    {
        @{$clistRef->[$i]} = map { $this->{parser}->sign($_) } @{$clistRef->[$i]};
    }
}

sub buildCallListAsOne
{
    my $this = shift;
    my @ids = map {$_->id()} @{$this->{selection}};
    @{$this->{callListAsOne}} = map { $this->{parser}->sign($_) } @{$this->{parser}->getCallListAsOne(\@ids)};
}

sub applyTreeSelection
{
    my $this = shift;

    if(defined($this->{maxHeight}))
    {
        @{$this->{trees}} = grep { $_->height() <= $this->{maxHeight} } @{$this->{trees}};
    }
    
    if(defined($this->{maxNodes}))
    {
        @{$this->{trees}} = grep { $_->numberOfNodes() <= $this->{maxNodes} } @{$this->{trees}};
    }
    
    if(defined($this->{minHeight}))
    {
        @{$this->{trees}} = grep { $_->height() >= $this->{minHeight} } @{$this->{trees}};
    }
    
    if(defined($this->{minNodes}))
    {
        @{$this->{trees}} = grep { $_->numberOfNodes() >= $this->{minNodes} } @{$this->{trees}};
    }
}

sub applyTreeSort
{
    my $this = shift;

    if(defined($this->{optTreeSort}))
    {
        if($this->{optTreeSort} eq "heightSort")
        {
            @{$this->{trees}} = sort {$b->height() <=> $a->height()} @{$this->{trees}};
        }
        elsif($this->{optTreeSort} eq "nodeSort")
        {
            @{$this->{trees}} = sort {$b->numberOfNodes() <=> $a->numberOfNodes()} @{$this->{trees}};
        }
    }
}

sub buildLinePrefixes
{
    my $this = shift;
    $this->{prefixes} = [];

    if(!defined($this->{linePrefix}))
    {
        @{$this->{prefixes}} = ("") x @{$this->{selection}};
        return;
    }

    foreach(@{$this->{selection}})
    {
        push @{$this->{prefixes}}, $this->interpretLine($this->{linePrefix}, $_);
    }
    
    
}

sub buildLineSuffixes
{
    my $this = shift;
    $this->{suffixes} = [];

    if(!defined($this->{lineSuffix}))
    {
        @{$this->{suffixes}} = ("\n") x @{$this->{selection}};
        return;
    }

    foreach(@{$this->{selection}})
    {
        push @{$this->{suffixes}}, $this->interpretLine($this->{lineSuffix}, $_);
    }
    
    
}


sub interpretLine
{
    my ($this, $descriptor, $routine) = @_;
    return "" if($descriptor =~ m/$_blank_match/);
    $descriptor =~ s/$_incoming_list_replace/join "\n", @{$this->{parser}->getIncomingSignatures($routine->id())}/eg;
    $descriptor =~ s/$_incoming_replace/@{$this->{parser}->in($routine->id())}/eg;
    $descriptor =~ s/$_outgoing_replace/@{$this->{parser}->out($routine->id())}/eg;
    $descriptor =~ s/$_callnumber_replace/$this->{parser}->callnb($routine->id())/eg;
    $descriptor =~ s/\\n/\n/g;
    return $descriptor;
}

sub hashResume
{
    my $hashRef = shift;
    my $result;
    foreach my $val (values(%$hashRef))
    {
        $result .= "\t" . join(", ", @$val) . "\n";
    }
    return $result;
}

sub nestedHashResume
{
    my $hashRef = shift;
    my $result;
    foreach my $optVal (values(%$hashRef))
    {
        foreach my $val (values %$optVal)
        {
            $result .= "\t" . join(", ", @$val) . "\n";   
        }
    }
    return $result;
}

1;
