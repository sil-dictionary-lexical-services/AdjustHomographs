#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--logfile logfile.log] [--debug] [file.sfm]";
=pod
This script checks for multiple instances of homographs and assigns homograph numbers to entries, subentries (complex forms) and variants that occur more than once.

This script reads an ini file for The SFMs for:
	* Record (e.g. \lx)
	* SubEntries (e.g. \se etc)
	* Variant forms (e.g. \va etc)
	* Main form reference? (\mn)
	* Citation form (e.g. \lc)

It opl's the SFM file on the record marker making the following arrays:
	* the array @opledfile_in contains the opl'ed record
	* the array @recordindex contains the line number of the first line of the record.
		* line and record counts start at 0
		* $recordindex[54] == 289
			means that line #290 will be the \lx line of the 55th record

It grinds over the opl'ed file building 3 hashes on the contents of the above fields:
	* %hmcount contains the number of occurences of the word
		* i.e. $hmcount{'someword'} is the no. of times 'someword' exists in the fields
	* %largesthm contains the largest homograph number for the word in the file
		* i.e. $largesthm{'someword'} == 6
			means that 6  'someword6' or '\lx someword#\hm 6' exists somewhere and 7 doesn't
	* %hmlocation contains record#<tab>field# indexed on <word><tab><hm#>
		* if the hm# is in the text, use that
		* otherwise hm# is numbered sequentially down from UNASSIGNED (9999)
		* i.e. if $recordindex[456] == 8329
		* $hmlocation{'someword<tab>3'} == '456<tab>12'
			means that line #8340 (8329+12, 0 index) is '\xx someword3' (\xx is \va or \se, etc.)
		* $hmlocation{'someotherword<tab>9997'} == '456<tab>24'
			means that line #8352 (8329+24, 0 index) is '\xx someotherword'
			and that there have been 2 other '\xx someotherword" fields before it (9999 &9998)
To parse \lx field for homograph
	* \lx word#...\hm n#
		* what can the ... be?
	* regex is /\\$recmark ([^#]+)#(.*?)\$hmmark ([^#]+)/
		* $form =$1;
		* $hmvalue = $3;
To parse \se* fields for homograph
	* \se word<n>#
	* regex is /\\$srchSEmarks ([^#]+)([0-9]*

To parse \va* for homograph
	* same as \se

Assign unassigned numbers 
	grind through %hmcount hash
		if current $hmcount > 1
			count down from 9999 until no hit
				build a reference at the corresponding $hmlocation
				do it in a way that doesn't change the field count

grind over the data array
	change the new references to proper SFM records
write out the file


The ini file should have sections with syntax like this:
[AdjstHm]
recmarks=lx
semarks=se,sec,sed,sei,sep,sesec,sesed,sesep,seses
vamarks=va,vap
lcmarks=lc

=cut

use 5.020;
use utf8;
use open qw/:std :utf8/;

use strict;
use warnings;
use English;
use Data::Dumper qw(Dumper);

use File::Basename;
my $scriptname = fileparse($0, qr/\.[^.]*/); # script name without the .pl

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "$scriptname.ini"), # ini filename
	'section:s'   => \(my $inisection = "AdjstHm"), # section of ini file to use
	'logfile:s'   => \(my $logfilename = "$scriptname.log"), # log filename
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'debug'       => \my $debug,
	) or die $USAGE;

open(my $LOGFILE, '>', $logfilename)
	or die "Could not open file '$logfilename' $!";

say STDERR "inisection:$inisection" if $debug;

use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
my $recmark;
my $hmmark;
my $srchSEmarks;
my $srchVAmarks;
my $lcmark;
if ($config) {
	$recmark = $config->{"$inisection"}->{recmark};
	$hmmark = $config->{"$inisection"}->{hmmark};
	my $semarks = $config->{"$inisection"}->{semarks};	
	$semarks  =~ s/\,*$//; # no trailing commas
	$semarks  =~ s/ //g;  # no spaces
	$semarks  =~ s/\,/\|/g;  # use bars for or'ing
	$srchSEmarks = qr/$semarks/;
	my $vamarks = $config->{"$inisection"}->{vamarks};
	$vamarks  =~ s/\,*$//; # no trailing commas
	$vamarks  =~ s/ //g;  # no spaces
	$vamarks  =~ s/\,/\|/g;  # use bars for or'ing
	$srchVAmarks = qr/$vamarks/;
	$lcmark = $config->{"$inisection"}->{lcmark};
	}
else {
	die  "Couldn't find the INI file: $inifilename\n";
	}
say STDERR "record mark:$recmark" if $debug;
say STDERR "homograph mark:$hmmark" if $debug;
say STDERR "subentry marks Match: $srchSEmarks" if $debug;
say STDERR "variant marks Match: $srchVAmarks" if $debug;
say STDERR "citation mark:$lcmark" if $debug;

my $UNASSIGNED = 99999;

# generate array of the input file with one SFM record per line (opl)
my @opledfile_in;
my @recordindex;

my $line = ""; # accumulated SFM record
my $linecount = 0 ;
while (<>) {
	s/\R//g; # chomp that doesn't care about Linux & Windows 
	s/#/\_\_hash\_\_/g;
	$_ .= "#";
	if (/^\\$recmark /) {
		$line =~ s/#$/\n/;
		push @opledfile_in, $line;
		push @recordindex, $NR;
		$line = $_;
		}
	elsif (/^\\$hmmark (.*?)#/) {
		my $hmval = $1;
		if (! $hmval) {
			s/\\$hmmark/\\${hmmark}bad/;
			say $LOGFILE "Bad homograph number (missing or 0), changing the SFM on line $.:$_";
			}
		elsif (! $hmval =~  m/ \d+/) {
			s/\\$hmmark/\\${hmmark}bad/;
			say $LOGFILE "Bad homograph number (not a number), changing the SFM on line $.:$_";
			}
		elsif (($hmval+0) > ($UNASSIGNED-9999)) {
			s/\\$hmmark/\\${hmmark}bad/;
			say $LOGFILE "Bad homograph number (too big), changing the SFM on line $.:$_";
			}
		 $line .= $_ ;
		}
	else { $line .= $_  }
	}
push @opledfile_in, $line;
push @recordindex, $NR;

my $sizeopl = scalar @opledfile_in;
say STDERR "size opl:", $sizeopl if $debug;

say STDERR @opledfile_in if $debug;
say STDERR "size index:", scalar @recordindex  if $debug;
print STDERR Dumper(@recordindex) if $debug;

my %hmcount;
my %largesthm;
my %hmlocation;
for (my $oplindex=0; $oplindex < $sizeopl; $oplindex++) {
	my $oplline = $opledfile_in[$oplindex];
	next if ! ($oplline =~  m/\\$recmark /); # e.g. Shoebox header line

	# \lx field
	$oplline =~  m/(^\\$recmark ([^#]+)#)/;
	say STDERR "lxfield: ", $1 if $debug;
	my $form=$2;
	my $hmvalue="";
	if  ($oplline =~  m/\\$hmmark ([^#]+)#/) {
		$hmvalue = $1;
		}
	say STDERR "hmvalue: ", $hmvalue if $debug;
	update_hmhashes($form, $hmvalue, $oplindex, 0); # \lx field# is always 0

	# \se, \sec etc


	# perhaps \va etc can go here too
	# loop through the matching fields and update_hmhashes() them too

	}
say STDERR "hmcount: ", Dumper \%hmcount if $debug;
say STDERR "largesthm: ", Dumper \%largesthm if $debug;
say STDERR "hmlocation : ", Dumper \%hmlocation if $debug;


sub update_hmhashes {
# updates  %hmcount, %largesthm, %hmlocation
my ($form, $hmvalue, $recnumber, $fieldnumber) = @_;
if (! exists $hmcount{$form}) {
	$hmcount{$form}=1;
	}
else {$hmcount{$form}++}

if ($hmvalue) {
	if (! exists $largesthm{$form} || ($largesthm{$form} < $hmvalue)) {
		 $largesthm{$form} = $hmvalue;
		}
	$hmlocation{"$form\t$hmvalue"} = "$recnumber\t$fieldnumber";
	}
else {
	my $newvalue;
	for ($newvalue = $UNASSIGNED; exists $hmlocation{"$form\t$newvalue"}; $newvalue--) {};
	$hmlocation{"$form\t$newvalue"} = "$recnumber\t$fieldnumber";
	}
}
# 
