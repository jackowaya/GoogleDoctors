#! /usr/bin/perl 
# Main runner for fixup. Downloads and parses files for one type of website.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";
use ParsingFramework::ParsingRunner;

use FixupDownloader;
use FixupParser;
use SubparserManager;

my $usage = "Usage fixup.pl parser search-results-txt-path download-path results-path\nfixup.pl list will list available parsers\n";

my $subparserManager = SubparserManager->new();

if (scalar(@ARGV) == 0) {
    print $usage;
    exit(0);
}

if (scalar(@ARGV) != 4) {
    print $usage;
    if (scalar(@ARGV) > 0 && lc($ARGV[0]) eq "list") {
	my %subparsers = $subparserManager->getSubparsers('');
	foreach my $key (keys(%subparsers)) {
	    print "$key\n";
	}
    }
    exit(0);
}

my $parserName = lc(shift @ARGV);
my $inputFile = shift @ARGV;
my $downloadDir = shift @ARGV;
my $resultDir = shift @ARGV;

my %subparsers = $subparserManager->getSubparsers($resultDir);
my @subparserList = values(%subparsers);

my $parser;
if (defined($subparsers{$parserName})) {
    $parser = FixupParser->new($subparsers{$parserName});
} else {
    print "No such parser $parserName. Use runner.pl list to find available parsers\n";
    exit(1);
}

$parser->init();

my $downloader = FixupDownloader->new($downloadDir, $parser);

my $runner = ParsingRunner->new($downloader, $parser);

$runner->run($inputFile);

$parser->teardown();
