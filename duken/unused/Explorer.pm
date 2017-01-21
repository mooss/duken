package duken::Explorer;
use strict;
use warnings;
use v5.14;
use constant TRUE => 1;
use constant FALSE => 0;

sub new
{
    
    my ($class, $folder) = @_;
    $class = ref($class) || $class;
    my $this = {};
    bless($this, $class);

    $folder =~ s/\/$//;
    $this->{_FOLDER} = $folder;
    $this->{_HEADERS} = [];
    $this->{_SOURCES} = [];

    return $this;
}

sub explore
{
    my ($this, $dir) = @_;
    my @cppFiles;
    my @hFiles;

    my $folderToExplore = $dir // $this->{_FOLDER};#assigne $this->{_FOLDER} comme valeur par default si dir n'est pas défini
    say "exploration de $folderToExplore";

    opendir(RACINE, $folderToExplore) or die $!;
    my @fileList = readdir(RACINE);
    closedir(RACINE);
    
    foreach my $file (@fileList)
    {
        next if($file =~ m/^\./);
        $file = "$folderToExplore/$file";
        if(-r $file)
        {
            if(-f $file)
            {
                if($file =~ m/.*\.cpp$/)
                {
                    #say "cpp found : $file";
                    push(@{$this->{_SOURCES}}, $file);
                }
                elsif($file =~ m/.*\.h$/)
                {
                    #say "h found : $file";
                    push(@{$this->{_HEADERS}}, $file);
                }
            }
            elsif(-d $file)
            {
                #say "dir found : $folderToExplore/$file";
                $this->explore("$file");
            }
            
        }
        else
        {
            say "impossible de lire $file";
        }
    }

}


1;
