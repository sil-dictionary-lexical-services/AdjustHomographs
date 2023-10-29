# Adjust Homographs
This repo contains a script to number homographs within an SFM (Standard Format Marker) lexicon file. It is a re-write of the DLS AddHomographs repo. A homograph pair are two words that are different words, but have the same spelling.

The main script in this repo is **AdjstHm.pl.** It goes through various fields of an SFM looking for homographs. When it finds homographs, it notes any of the homographs that already have a number. It won't change any pre-existing numbers. Any homographs that aren't already numbered are assigned new numbers. They receive numbers greater than any numbers already assigned.

## Running the script

Edit the .**INI** file to say which SFMs are used to mark records and fields that can contain homographs. A model **.INI** file, **AdjstHm.ini** is included with the repo and is explained below.

If you use WSL, make sure the script has Linux line endings. The script will correctly read SFM and .INI files that have Windows line endings. The output file will contain Linux line endings.

It's easiest to copy the script, your **.INI** file, and your SFM file into a working directory and navigate to that. The instructions below assume that they are in the current directory.

You also need the utility scripts [oplsfm.pl](https://github.com/sil-dictionary-lexical-services/Opl_DeOpl/blob/master/oplsfm.pl) and [de_oplsfm.pl](https://github.com/sil-dictionary-lexical-services/Opl_DeOpl/blob/master/de_oplsfm.pl) in the same working directory, as well as the **AdjstHm.sh** file.

(To run the sample data, copy these files into the **SampleData** folder.  Run the script as explained below.  Then compare the output files with the files that are in the **ExpectedOutput** folder there.)

There are several steps to the process of running this script.  There are two ways to accomplish this.

### Option 1: Use the supplied shell script

Once the **INI** file has been edited and the main **AdjstHm.pl** script has the correct line endings, and the needed utility scripts are in the working directory, run the whole sequence with this command:

````bash
./runAdjHm.sh InputSFM.db OutputSFM.db
````

### Option 2: Run each step of the process manually

If you want to see the intermediate files and see how each part is called, first run a sequence of commands that flags any references in the file, so they won't be part of the calculations:

````bash
./oplsfm.pl < InputSFM.db | ./FlagseReF.pl | ./de_oplsfm.pl > InputSFM-ref.db
````

Then use the output of that to run the script with default arguments:

````bash
./AdjstHm.pl InputSFM-ref.db > OutputSFM.db
````

To see the possible arguments use the **--help** option:

````bash
$ ./AdjstHm.pl --help
Usage: ./AdjstHm.pl [--inifile AdjstHm.ini] [--section section] [--logfile AdjstHm-log.txt] [--errfile AdjstHm-err.txt] [--debug] [file.sfm]
A script that assigns homograph numbers to un-numbered homographs in a Standard Format lexicon file.
````

## How homographs are marked

When an item in a lexical form has a homograph number it is marked by the presence of a **\hm** field with its number. This field normally occurs immediately after the **\lx** field. Here are two homographs of 'bear' from the [Pig Latin](https://en.wikipedia.org/wiki/Pig_Latin)  [BearBullMole](https://github.com/sil-dictionary-lexical-services/SubentryPromotion/blob/master/SampleFiles/BearBullMole-complex.db) database:

````SFM
\lx earbay
\hm 1
\et Middle English: bere
\sn 1
\ps n
\de a large omnivorous mammal, having shaggy hair, ...
...

\lx earbay
\hm 6
\et Middle English: beren
\vap orebay9
\va ornebay
\sn 1
\ps vt
\de to carry upon one's person, especially visibly ...
````

When an entry contains a reference (that is, a single \va or \se field that points to a different entry) to a variant or a subentry that has a homograph number, it's marked by a number attached to the last  word of the field.  These fields are not included in the calculations to determine which words are homographs, since they are only pointers to other entries that ARE part of the calculations.

When there is an embedded subentry (that is, not just the \se field pointing at another entry, but all of the subentry information occurs embedded in the parent entry), the hm number needs to be attached to the last word of the \se field in this case also, and the contents of this field are included in the calculations to determine when entries are homographs.

For example, 'bore' is the variant past form of 'to bear' (see the \vap field above); it's also a subentry as a noun under the verb 'to bore'. As the variant ref above, it already displays the hm number of the entry it points to: 9. As a subentry below (see the \sed field below), it hasn't yet been assigned a number.

````SFM

\lx orebay
\hm 1
\ps vt
\de to inspire boredom in somebody
\xv Isway ifelay otnay away ousandthay imestay ootay ortshay orfay usway otay orebay ourselvesway?
\xe Is life not a thousand times too short for us to bore ourselves?
\sed orebay
\ps n
\de one who inspires boredom or lack of interest
...
````

After running the script, the subentry would have a homograph number, like this:

````SFM
\sed orebay10
\ps n
\de one who inspires boredom or lack of interest
...
````

You can see it was marked as homograph #10 of 'bore'.

## Which fields are searched for homographs?

The .INI file (default **AdjustHm.ini**) specifies the SFMs of fields that are searched for homographs. Here is a sample:

````ini
[AdjstHm]
recmark=lx
hmmark=hm
semarks=se,sec,sed,sei,sep,sesec,sesed,sesep,seses
vamarks=va,vap
lcmark=lc
````

The semarks fields are considered to be a reference if no other subentry field follows them: that is, if they are followed by another semark, the date field, or the end of the entry. They are considered as the lexical form of an actual subentry (and eligible to be part of the hm calculations) if other fields follow them. The vamarks fields are all considered to be references.  

Only a single SFM can be used for the following field types

1. record marker/lexical form (\lx)
2. homograph field (\hm)
3. citation form (\lc)

Subentries (\se\*) and variants (\va) can have more than one SFM to indicate its type. Multiple values are separated by commas.

The lexical form field is searched for homographs. See below how that is affected by citation forms.

## How the **AdjustHm.pl** script numbers homographs

The script goes through the SFM file gathering the fields into records. As it does that, it makes sure that the **\hm** fields are numeric and are reasonable.

Then the script reads through the SFM records counting the occurrences of the forms that are part of the hm calculations. It notes where they occur, and their homograph number if they have one. It also keeps track of the maximum number that has already been assigned as homograph number for each form.

After the scan, if a form has more than one homograph, the script goes through the occurrences that don't have a number and assigns numbers. It starts assigning numbers with the current maximum assigned number, plus one. It writes the homograph numbers into the SFM file according to the scheme above, i.e., with a homograph field for lexical and citation forms and with a trailing homograph number for subentries and variants.

When the script has assigned the homograph numbers, it breaks the records back into the proper fields and writes the file out to the Standard Output.

## How citation forms affect the numbering

If the entry has a citation form (e.g., **\lc**), that form is used instead of the one in the lexical field (e.g. **\lx**). In that case, the contents of the **\lx** field aren't included in the count for homographs in other entries. If there is an **\hm** number in the record already, it will be used as the homograph number when calculating numbers for other entries that match the citation form.

## Reporting homograph numbering errors in the log file

The script detects homograph fields that are invalid (because they don't have a number) or contain a homograph number greater than 90000. It logs them to the log file. Line numbers in the log file refer to the line number in the input file, which may be different from the output file.

If the script detects that a homograph number has been assigned twice, It reports the form and line number of the two occurrences. Note that in the case of a lexical form or a citation form, the form and the homograph field will be on different lines.

## Bugs & Possible Enhancements

**AdjstHm.pl** doesn't detect missing homograph numbers. It starts assigning new numbers after the largest existing number. It doesn't check for gaps in the existing homograph numbering.

**AdjstHm.pl** doesn't detect duplicate assigned homograph numbers. It currently assumes that assigned homograph numbers are correct and doesn't change them.

When an entry that receives a new hm number has references to other entries (e.g., \va or \se or any lexical relations) **AdjstHm.pl** doesn't follow the references and apply the new hm number to the back references in those entries.

Other Bugs: probably, viz.

> Undetectable errors are infinite in variety, in contrast to detectable errors, which by definition are limited. Gilb's 7th Law of Unreliabilty, Datamation, March 1975
