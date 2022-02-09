# Adjust Homographs
This repo contains a script to number homographs within an SFM (Standard Format Marker) lexical file. It is a re-write of the DLS AddHomographs repo. A homograph pair are two words that are different words, but have the same spelling.

The main script in this repo is **AdjustHm.pl.** It goes through various fields of an SFM looking for homographs. When it finds homographs, it notes any of the homographs that already have a number. It won't change any pre-existing numbers. Any homographs that aren't already numbered are assigned new numbers. They receive numbers greater than any numbers already assigned.

## Running the script

Edit the .**INI** file to say which SFMs are used to mark records and fields that can contain homographs. A model **.INI** file, **AdjstHm.ini** is included with the repo and is explained below.

If you use WSL, make sure the script has Linux line endings. The script will correctly read SFM and .INI files that have Windows line endings. The output file will contain Linux line endings.

It's easiest to copy the script, your **.INI** file, and your SFM file into a working directory and navigate to that. The instructions below assume that they are in the current directory.

Run the script with default arguments:

````bash
./AdjstHm.pl InputSFM.db >OutputSFM.db
````

To see the possible arguments use the **--help** option:

````bash
$ ./AdjstHm.pl --help
Usage: ./AdjstHm.pl [--inifile AdjstHm.ini] [--section section] [--logfile AdjstHm.log] [--debug] [file.sfm]
A script that assigns homograph numbers to un-numbered homographs in a Standard Format File lexical file.
````

## How homographs are marked

When an item in a lexical form has a homograph number it is marked by the presence of a **\hm** field with its number. Here are two homographs of 'bear' from the [Pig Latin](https://en.wikipedia.org/wiki/Pig_Latin) BearBullMole database:

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

When the homograph is a variant or a subentry of entry, it's marked by a number attached to the last word of the field.

For example, 'bore' is the variant past form of 'to bear' (see the \vap field above); it's also a subentry as a noun under the verb 'to bore'. As the variant above, it has already been assigned the number 9. As a subentry below (see the \sed field below), it hasn't yet been assigned a number.

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

Only a single SFM can be used for the following field types

1. record marker/lexical form (\lx)
2. homograph field (\hm)
3. citation form (\lc)

Subentries (\se\*) and variants (\va) can have more than one SFM to indicate its type. Multiple values are separated by commas.

The lexical form field is searched for homographs. See below how that is affected by citation forms.

## How the **AdjustHm.pl** script numbers homographs

The script goes through the SFM file gathering the fields into records. As it does that, it makes sure that the **\hm** fields are numeric and are reasonable.

Then the script reads through the SFM records counting the occurrences of the forms. It notes where they occur, and their homograph number if they have one. It also keeps track of the maximum number that has already been assigned as homograph number for each form.

After the scan, if a form has more than one homograph, the script goes through the occurrences that don't have a number and assigns numbers. It starts assigning numbers with the current maximum assigned number, plus one. It writes the homograph numbers into the SFM file according to the scheme above, i.e., with a homograph field for lexical and citation forms and with a trailing homograph number for subentries and variants.

When the script has assigned the homograph numbers, it breaks the records back into the proper fields and writes the file out to the Standard Output.

## How citation forms affect the numbering

If the entry has a citation form (e.g., **\lc**), that form is used instead of the one in the lexical field (e.g. **\lx**). In that case, the contents of the **\lx** field aren't included in the count for homographs in other entries. If there is an **\hm** number in the record already, it will be used as the homograph number when calculating numbers for other entries that match the citation form.

## Reporting homograph numbering errors in the log file

The script detects homograph fields that are invalid (because they don't have a number) or contain a homograph number greater than 90000. It logs them to the log file. Line numbers in the log file refer to the line number in the input file, which may be different from the output file.

If the script detects that a homograph number has been assigned twice, It reports the form and line number of the two occurrences. Note that in the case of a lexical form or a citation form, the form and the homograph field will be on different lines.

## Bugs & Enhancements

**AdjustHm.pl** doesn't detect missing homograph numbers. It starts assigning new numbers after the largest existing number. It doesn't check for gaps in the existing homograph numbering.

**AdjustHm.pl** doesn't detect duplicate assigned homograph numbers. It currently assumes that assigned homograph numbers are correct and doesn't change them.

Other Bugs: probably, viz.

> Undetectable errors are infinite in variety, in contrast to detectable errors, which by definition are limited. Gilb's 7th Law of Unreliabilty, Datamation, March 1975
