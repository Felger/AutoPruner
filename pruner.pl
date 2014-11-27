#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use autodie;
use Cwd;
use FindBin qw($Bin);       # $Bin is where our executable is
use File::Spec;

if (@ARGV !=2) {
    say "\nTo prune  : $0 -prune prunelist";
    say "To unprune: $0 -unprune prunelist\n";
}
else
{
    my $action = $ARGV[0];
    my $prunelist = $ARGV[1];
    my $BaseDir = 'GameData';
    
    # Assuming we're always in the Pruner/ directory in the KSP directory, figure
    # out where GameData will be.
    my $dir = File::Spec->catdir($Bin,"..",$BaseDir);

    open(my $prune_fh, '<', "$Bin/$prunelist");
    my @prunearray;
    while (my $row = <$prune_fh>) {
      chomp $row;
      push (@prunearray,$row);
    }
    close $prune_fh;
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
    else
    {
        die "Usage: $0 [-prune|--unprune] prunelist\n";
    }
    print join("\n",@prunearray);
    print "\n\n\tProceed?\n\n\t   [ Y / N ]?";
    chomp($key = <STDIN>);  ## no critic 'ProhibitExplicitStdin'
    
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

    for (glob("\Q$path\E/*"))
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

    return;
}
