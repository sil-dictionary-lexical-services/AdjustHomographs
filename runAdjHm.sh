#!/bin/bash
# call this like:
#    dbname=myfile.sfm ./runAdjHm.sh

# The next variables should be set before the script is run
# if it's not, a default is used
dbname="${dbname:-adjust.sfm}"

bkpdbname="${dbname%.*}.bkp" # replace extension with bkp
refdbname="${dbname%.*}.ref" # replace extension with ref
echo "Original:$bkpdbname Reference Flagged:$refdbname Modified:$dbname"
cp $dbname $bkpdbname
perl -pf opl.pl $bkpdbname |./FlagseReF.pl |perl -pf de_opl.pl |tee $refdbname |./AdjstHm.pl |perl -pE 's/^\\REF/\\/' >$dbname
