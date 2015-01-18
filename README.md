AutoPruner
==========

Save RAM by pruning files from your KSP installation, and hiding them from the loader.

How to use:

On Windows:
Run the StartThis.bat batch file to open a command prompt in this directory.  
run:  
  pruner -prune FASA_Tanks.prnl    
To prune all FASA tanks defined in the prunelist (.prnl)  
run:  
  pruner -unprune FASA_Tanks.prnl  
To undo what you did, since you realized that you really did want those tanks.

On Linux or Mac:
Open a terminal window and descend to the PRNLs directory.
run:
  ./pruner.pl -prune FASA_Tanks.prnl
To prune all FASA tanks defined in the prunelist (.prnl)  
run:  
  ./pruner.pl -unprune FASA_Tanks.prnl  
To undo what you did, since you realized that you really did want those tanks.

Other options:
run:
  pruner -list
To receive a list of all available prunelists.

This methodology is chosen to preserve tab completion for the prunelist filenames.