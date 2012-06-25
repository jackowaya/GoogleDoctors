#! /usr/bin/perl 
# Parses files in a single directory with the specified parser.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";

use GoogleDownloader;
use GoogleParser;
use SubparserManager;

my $usage = "Usage parse.pl parser download-path results-path\nparse.pl list will list available parsers\n";

my $subparserManager = SubparserManager->new();

if (scalar(@ARGV) == 0) {
    print $usage;
    exit(0);
}

if (scalar(@ARGV) != 3) {
    print $usage;
    if (scalar(@ARGV) > 0 && lc($ARGV[0]) eq "list") {
	print "all - All parsers in below list will be run\n";
	my %subparsers = $subparserManager->getSubparsers('');
	foreach my $key (keys(%subparsers)) {
	    print "$key\n";
	}
    }
    exit(0);
}

my $parser = lc(shift @ARGV);
my $downloadDir = shift @ARGV;
my $resultDir = shift @ARGV;

my %subparsers = $subparserManager->getSubparsers($resultDir);
my @subparserList = values(%subparsers);

my $googleParser;
my @parsers;
if ($parser eq "all") {
    @parsers = @subparserList;
} else {
    if (defined($subparsers{$parser})) {
	@parsers = ($subparsers{$parser});
    } else {
	print "No such parser $parser. Use runner.pl list to find available parsers\n";
	exit(1);
    }
}

foreach my $parserObj (@parsers) {
    $parserObj->init();
}

opendir(DIR, $downloadDir);
my @files = readdir(DIR);
closedir(DIR);
my $id = 1;
foreach my $file (@files) {
    if ($file !~ m/^\./) {
	foreach my $parserObj (@parsers) {
	    $parserObj->parse($id, "$downloadDir/$file");
	    $id++;
	}
    }
}

foreach my $parserObj (@parsers) {
    $parserObj->teardown();
}
