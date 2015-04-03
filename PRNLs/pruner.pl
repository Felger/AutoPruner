#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use autodie;
use Cwd;
use FindBin qw($Bin);       # $Bin is where our executable is
use File::Spec;
use File::Find qw(find);

## no critic qw(ProhibitConstantPragma RequireExtendedFormatting)

use constant EXIT_OK => 0;
use constant EXIT_BADOPT => 1;

# Calling main(@ARGV) helps prevent variable leakage, and makes testing easier later on.
exit main(@ARGV);

sub main {
    my @args = @_;
    my $force = 0;
    if (@args !=3 && @args !=2 && @args !=1) 
    {
        say "\nTo prune           : $0 [-force] -prune prunelist";
        say "To unprune         : $0 [-force] -unprune prunelist";
        say "To view prunelists : $0 -list\n";
        return EXIT_BADOPT;
    }
    elsif (@args ==1 && $args[0] ne '-list')
    {
        say "\nTo prune         : $0 [-force] -prune prunelist";
        say "To unprune         : $0 [-force] -unprune prunelist\n";
        say "To view prunelists : $0 -list\n";
        return EXIT_BADOPT;
    }
    elsif (@args ==3 && $args[0] ne '-force')
    {
	say "\nTo prune           : $0 [-force] -prune prunelist";
        say "To unprune         : $0 [-force] -unprune prunelist";
        say "To view prunelists : $0 -list\n";
        return EXIT_BADOPT;
    }
    if ($args[0] eq '-force')
    {
        shift(@args);
        $force = 1;
    }
    my $action = $args[0];
    my $prunelist = $args[1];
    my $BaseDir = 'GameData';
    
    # Assuming we're always in the AutoPruner/PRNLs directory in the KSP directory, figure
    # out where GameData will be.
    my $dir = File::Spec->catdir($Bin,"../..",$BaseDir);
    my (@prunearray,@files);
    if ($action eq '-prune' || $action eq '-unprune')
    {
        open(my $prune_fh, '<', "$Bin/$prunelist");
        chomp(@prunearray = <$prune_fh>);
        close $prune_fh;
        # Find all the files we might take action on.
        @files = sort( locate_files($dir, \@prunearray) );
    }
    elsif ($action eq '-list')
    {
    }




    print "==================================================\n";
    if ($action eq '-prune')
    {
        print "Pruning files matching $prunelist:\n";
    }
    elsif ($action eq '-unprune')
    {
        print "Unpruning files defined in $prunelist:\n";
    }
    elsif ($action eq '-list')
    {
        print "Available prunelists (.prnl):\n";
        opendir(my $prnlDIR, "$Bin") 
             or die "Can't open $Bin $!";
        my @prnlarray = readdir $prnlDIR;
        @prnlarray = File::Spec->no_upwards(@prnlarray);
		@prnlarray = grep { $_ ne 'pruner.pl' && $_ ne 'pruner.exe' } @prnlarray;
        @prnlarray = sort @prnlarray;
        closedir $prnlDIR;
        print "\t".join("\n\t",@prnlarray)."\n";
        return EXIT_OK;
    }
    else
    {
        die "Usage: $0 [-force] [-prune|-unprune] prunelist | -list\n";
    }
    print join("\n",@prunearray);
    my $key = 'N';
    printf "\n\n\tProceed (up to %d files to rename)", scalar @files;
    if (!$force) 
    {
        print "?\n\n\t   [ Y / N ]?";
        chomp($key = <STDIN>);  ## no critic 'ProhibitExplicitStdin'
    } 
    if ($key eq 'y' || $key eq 'Y' || $force)
    {
        print "\n-----Executing-----\n\n";

        chdir($dir);    # Work from GameData

        if ($action eq '-prune') {
            foreach my $file (@files) {
                next if $file =~ m{\.pruned$};  # Skip already pruned files

                say "Pruning $file...";
                rename($file, "$file.pruned");
            }
        }
        elsif ($action eq "-unprune") {
            foreach my $file (@files) {
                next if $file !~ m{^(?<base>.*)\.pruned$};  # Only work with pruned files

                say "Unpruning $file...";
                rename($file, $+{base});
            }
        }
    }

    say "\nDone!";
    return EXIT_OK;
}

=head1 SUBROUTINES

=head2 locate_files

    my @files = locate_files($gamedata, $prunearray);

Takes a path to GameData and an arrayref of rules and returns a set of files
with relative paths which match.

=cut

sub locate_files {
    my ($base, $prunearray) = @_;
    # Get our potential directories, adding our base on the front, and dropping
    # any that do not actually exist.
    my @directories = grep { -d } map { File::Spec->catdir($base, $_) } locate_dirs($prunearray);

    # If no directories are found, we have nothing to prune.
    if (not @directories) {
        warn "Found nothing to prune...\n";
        return;
    }

    # Since a file may match multiple rules, we'll keep them in a
    # hash, which is also conveniently a set. :)
    my %files;

    # Let's write a closure that can identify files we want!
    my $gather = sub {

        # Only process regular files
        return if not -f;

        my $path = $File::Find::name;

        # Remove our base first.
        $path =~ s{^\Q$base\E/?}{}
            or die "$path doesn't seem to be in $base"; ## no critic 'RequireCarping'
		$path =~ s/\\/\//g;
		$path =~ s/^\///;
        # Oh dear, this is O(N^2). But it's likely fast enough
        # nobody will care.
        foreach my $rule (@$prunearray) {
            # Now see if we're a match, remembering if we are.
            if ($path =~ m{^\Q$rule\E}) {
                $files{$path}++;
            }
        }
    };

    # And now let's find and return those files.
    # This populates %files.
    find($gather, @directories);
 
    return keys %files;
}

=head2 locate_dirs

    my @dirs = locate_dirs(@prunearray);

Takes an arrayref of rules and returns a set of relative directories that they
pertain to.

=cut

sub locate_dirs {
    my ($prunearray) = @_;

    # Hashes also make convenient sets. :)
    my %directories;

    # Rather than walking the whole of GameData, which can pick up ATM
    # caches and all manner of other things, instead we'll pick
    # out the paths that exist, and only walk those.
    foreach my $path (@$prunearray) {
        my $dir = (File::Spec->splitpath($path))[1];
        $directories{$dir}++;
    }

    return keys %directories
}
