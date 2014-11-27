use strict;
use warnings;
use Cwd;

my $argnum = $#ARGV +1;
if ($argnum !=2) {
    print "\nTo prune  : Filetinker.pl -prune prunelist\n";
    print "\nTo unprune: Filetinker.pl -unprune prunelist\n";
}
else
{
    my $action = $ARGV[0];
    my $prunelist = $ARGV[1];
    my $BaseDir = 'GameData';
    
    #Start with the current directory, and get our starting point.  We'll want to
    #drop into ExampleData and scan there.
    my $dir = getcwd;
    #Move up a directory, then Move to GameData to start scanning and pruning.
    $dir =~ s/\/([^\/])*$/\//;
    $dir = $dir.$BaseDir;
    open(PRUNELIST,$prunelist) or die "Couldn't open prunelist\n";
    my @prunearray;
    while (<PRUNELIST>) {
      my $row = $_;
      chomp $row;
      push (@prunearray,$row);
    }
    close PRUNELIST;
    my $key;
    
    print "==================================================\n";
    if ($action eq '-prune')
    {
        print "Pruning files matching $prunelist:\n";
    }
    elsif ($action eq '-unprune')
    {
        print "Unpruning files defined in $prunelist:\n";
    }
    print join("\n",@prunearray);
    print "\n\n\tProceed?\n\n\t   [ Y / N ]?";
    chomp($key = <STDIN>);
    
    if ($key eq 'y' || $key eq 'Y')
    {
        print "-----Executing-----\n\n";
        process_files ($dir,$BaseDir,$action,@prunearray);
    }
    else
    {
        print "-----Exiting script-----\n\n";
    }
}

# Accepts one argument: the full path to a directory.
# Returns: nothing.
sub process_files {
    my ($path, $BaseDir, $action, @prunearray) = @_;

    # Open the directory.
    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    # Read in the files and remove . and ..
    my @contains = grep { !/^\.{1,2}$/ } readdir (DIR);

    # Close the directory.
    closedir (DIR);

    # Put the whole path in the array entry.
    @contains = map { $path . '/' . $_ } @contains;
    
    for (@contains)
    {
        # If the file is a directory
        if (-d $_)
        {
            # Descend into the directories contained.  Do this before we screw
            # with filenames.
            process_files ($_,$BaseDir,$action,@prunearray);
            
			# Commented directory rename, don't want to conflict with other mods.
            # Rename the directory if it matches a pruned directory.
            # my $dir = $_;
            # if ($action eq '-prune')
            # {
                # foreach (@prunearray)
                # {
                    # #Check for each defined pruning action, if we need to prune
                    # if ($dir =~ /$_/ && !($dir =~ /-pruned/))
                    # {
                        # #Add -pruned to the directory name
                        # rename $dir,$dir."-pruned";
                        # $dir =~ s/^.*$BaseDir//;
                        # print $dir."-pruned\n";
                    # }
                # }
            # }
            # elsif ($action eq '-unprune')
            # {
                # foreach (@prunearray)
                # {
                    # if ($dir =~ /$_/)
                    # {
                        # #remove -pruned from the directory name
                        # my $unprunedir = $dir;
                        # $unprunedir =~ s/-pruned//;
                        # rename $dir,$unprunedir;
                        # $unprunedir =~ s/^.*$BaseDir//;
                        # print $unprunedir;
                    # }
                # }
            # }
        }
        else
        { 
            my $file = $_;
            if ($action eq '-prune')
            {
                foreach (@prunearray)
                {
                    if ($file =~ /$_/ && !($file =~ /\.pruned/))
                    {
                        #Add .pruned to the filename, preserving the 
                        rename $file,$file.".pruned";
                        $file =~ s/^.*$BaseDir//;
                        print $file.".pruned\n";
                    }
                }
            }
            elsif ($action eq '-unprune')
            {
                foreach (@prunearray)
                {
                    my $unprunedir = $_;
                    if ($file =~ /$unprunedir/)
                    {
                        #Create the unpruned filename, remove .pruned 
                        my $unpruned = $file;
                        $unpruned =~ s/\.pruned//;
                        rename $file,$unpruned;
                        $unpruned =~ s/^.*$BaseDir//;
                        print $unpruned."\n";
                    }
                }
            }
        }
    }
}