#!/bin/bash

# call this like:
#    ./runAdjHm.sh infile.db outfile.db

# Collect input/output filenames from command line
infilename=$1
outfilename=$2
# The name of the main script, to use for constructing filenames
scriptfilename="AdjstHm"
# Construct ancillary filenames
refdbname="${infilename%.*}-ref.txt" # create FlagRef filename
# This is what the script AdjstHm.pl is currently doing:
logfilename="$scriptfilename-log.txt" # create Log filename
errfilename="$scriptfilename-err.txt" # create Log filename
## If we want to construct the log/err files from the input filename
## (but we would have to pass them to the script)
#logfilename="${infilename%.*}-log.txt" # create Log filename
#errfilename="${infilename%.*}-err.txt" # create Log filename

# Report the filenames we're using
echo "Original:$infilename "
echo "Flagged Refs File:$refdbname"
echo "LogFile:$logfilename  ErrFile:$errfilename "
echo "Modified:$outfilename"

# Call the sequence of commands to run the operation
./oplsfm.pl < $infilename | ./FlagseReF.pl | ./de_oplsfm.pl |tee $refdbname | ./AdjstHm.pl | perl -pE 's/^\\REF/\\/' >$outfilename

# If the error file is empty, delete it
if ! [ -s "AdjstHm-err.txt" ];then
    #echo "Deleting empty Error file AdjstHm-err.txt"
	rm AdjstHm-err.txt
fi

