#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section section] [--logfile logfile.log] [--debug] [file.sfm]\nA script that checks an opl'd file for subentries that are references. Reference subentries are those that have no subfields.";
=pod
This script checks an opl'd file for subentries that are references.
Reference subentries are those that have no subfields.
It inserts a flag text into the SFM so that won't be matched in the AdjstHm script.
I.e., the \se field is immediately followed by:
	another se marker
	a date marker
	the end of the record
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
$USAGE =~ s/inifile\./$scriptname\./;

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "AdjstHm.ini"), # ini filename
	'section:s'   => \(my $inisection = "AdjstHm"), # section of ini file to use
	'help'    => \my $help,
# additional options go here.
# 'sampleoption:s' => \(my $sampleoption = "optiondefault"),
	'debug'       => \my $debug,
	) or die $USAGE;
if ($help) {
	say STDERR $USAGE;
	exit;
	}
say STDERR "inisection:$inisection" if $debug;

use Config::Tiny;
my $config = Config::Tiny->read($inifilename, 'crlf');
my $recmark;
my $REFflag;
my $srchDTmarks;
my $srchSEmarks;
if ($config) {
	$recmark = $config->{"$inisection"}->{recmark};
	$REFflag = $config->{"$inisection"}->{REFflag};
	my $semarks = $config->{"$inisection"}->{semarks};
	my $dtmarks = $config->{"$inisection"}->{dtmarks};
	for ($recmark, $semarks, $REFflag, $dtmarks) {
		# remove backslashes and spaces from the SFMs in the INI file
		say STDERR $_ if $debug;
		s/\\//g;
		s/ //g;
		}
	for ($semarks, $dtmarks) {
		s/\,*$//; # no trailing commas
		s/\,/\|/g;  # use bars for or'ing
		}
	$srchSEmarks = qr/$semarks/;
	$srchDTmarks = qr/$dtmarks/;
	}
else {
	die  "Couldn't find the INI file: $inifilename\n";
	}
say STDERR "record mark:$recmark" if $debug;
say STDERR "REF flag:$REFflag" if $debug;
say STDERR "subentry marks Match: $srchSEmarks" if $debug;
say STDERR "date marks Match: $srchDTmarks" if $debug;
while (<>) {
    while (s/\\($srchSEmarks)( [^#]*#+\\$srchSEmarks )/\\$REFflag$1$2/) {} # trailed by another subentry
    while (s/\\($srchSEmarks)( [^#]*#+\\$srchDTmarks( |#))/\\$REFflag$1$2/) {} # trailed by a date marker
    while (s/\\($srchSEmarks)( [^#]*#+$)/\\$REFflag$1$2/) {} # at the end of the record
		print;
}
