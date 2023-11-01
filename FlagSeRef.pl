#!/usr/bin/env perl
my $USAGE = "Usage: $0 [--inifile inifile.ini] [--section AdjustHm] [--logfile logfile.log] [--debug] [file.sfm]\nA script that checks a file for subentries that are references. Reference subentries are those that have no subfields.";
=pod
This script checks a file for subentries that are references.
Reference subentries are those that have no subfields.
It inserts a flag text into the SFM so that won't be matched in the AdjustHm script.
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
$USAGE =~ s/logfile\.log/$scriptname\-log.txt/;

use Getopt::Long;
GetOptions (
	'inifile:s'   => \(my $inifilename = "AdjustHm.ini"), # ini filename
	'section:s'   => \(my $inisection = "AdjustHm"), # section of ini file to use
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

# generate array of the input file with one SFM record per line (opl)
my $eolrep = "#"; # character used to replace EOL
my $reptag = "__hash__"; # tag to use in place of the EOL replacement character
my @opledfile_in;
my $line = ""; # accumulated SFM record
my $crlf;
while (<>) {
	$crlf = $MATCH if  s/\R//g;
	s/$eolrep/$reptag/g;
	$_ .= "$eolrep";
	if (/^\\$recmark /) {
		$line =~ s/$eolrep$/$crlf/;
		push @opledfile_in, $line;
		$line = $_;
		}
	else { $line .= $_ }
	}
push @opledfile_in, $line;

say STDERR "opledfile_in:", Dumper(@opledfile_in) if $debug;

for my $oplline (@opledfile_in) {
	while ($oplline =~ s/\\($srchSEmarks)( [^#]*#+\\$srchSEmarks )/\\$REFflag$1$2/) {} # trailed by another subentry
	while ($oplline =~ s/\\($srchSEmarks)( [^#]*#+\\$srchDTmarks( |#))/\\$REFflag$1$2/) {} # trailed by a date marker
	while ($oplline =~ s/\\($srchSEmarks)( [^#]*#+$)/\\$REFflag$1$2/) {} # at the end of the record

	say STDERR "oplline:", Dumper($oplline) if $debug;
	#de_opl this line
		for ($oplline) {
			$crlf=$MATCH if /\R/;
			s/$eolrep/$crlf/g;
			s/$reptag/$eolrep/g;
			print;
			}
}
