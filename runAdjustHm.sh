#!/bin/bash

# call this like:
#    ./runAdjustHm.sh infile.db outfile.db

# Collect input/output filenames from command line
infilename=$1
outfilename=$2
if [ ! -f $infilename ] || [ -z $outfilename ]; then
	echo -e "A script to assign homographs. Call it like this:\n$0 infile.db outfile.db"
	exit
	fi
# The name of the main script, to use for constructing filenames
scriptfilename="AdjustHm"
# Construct ancillary filenames
refdbname="${infilename%.*}-ref.${infilename##*.}" # create FlagRef filename
# This is what the script AdjustHm.pl is currently doing:
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
./FlagSeRef.pl < $infilename|tee $refdbname | ./AdjustHm.pl | perl -pE 's/^\\REF/\\/' >$outfilename

# If the error file is empty, delete it
if ! [ -s "AdjustHm-err.txt" ];then
    #echo "Deleting empty Error file AdjustHm-err.txt"
	rm AdjustHm-err.txt
fi

