#! /usr/bin/perl 
# Main runner for google doctors. Downloads and parses files.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";
use ParsingFramework::ParsingRunner;

use GoogleDownloader;
use GoogleParser;
use SubparserManager;

my $usage = "Usage runner.pl [-s|--skip-download] parser input-path download-path results-path\nrunner.pl list will list available parsers\n";

my $subparserManager = SubparserManager->new();

if (scalar(@ARGV) == 0) {
    print $usage;
    exit(0);
}

my $skipDownload = 0;
if ($ARGV[0] eq "-s" || $ARGV[0] eq "--skip-download") {
    $skipDownload = 1;
    shift @ARGV;
}

if (scalar(@ARGV) != 4) {
    print $usage;
    if (scalar(@ARGV) > 0 && lc($ARGV[0]) eq "list") {
	print "all - All parsers in below list will be run\n";
	print "none - Only google links parser will be run\n";
	my %subparsers = $subparserManager->getSubparsers('');
	foreach my $key (keys(%subparsers)) {
	    print "$key\n";
	}
    }
    exit(0);
}

my $parser = lc(shift @ARGV);
my $inputFile = shift @ARGV;
my $downloadDir = shift @ARGV;
my $resultDir = shift @ARGV;

my %subparsers = $subparserManager->getSubparsers($resultDir);
my @subparserList = values(%subparsers);

my $downloader = GoogleDownloader->new($skipDownload, $downloadDir);

my $googleParser;
if ($parser eq "all") {
    $googleParser = GoogleParser->new($resultDir, \@subparserList);
} elsif ($parser eq "none") {
    $googleParser = GoogleParser->new($resultDir, []);
} else {
    if (defined($subparsers{$parser})) {
	$googleParser = GoogleParser->new($resultDir, [$subparsers{$parser}]);
    } else {
	print "No such parser $parser. Use runner.pl list to find available parsers\n";
	exit(1);
    }
}
$googleParser->init();

if ($parser ne "none" && !$skipDownload) {
    my $approved = 0;
    until ($approved) {
	print "You have not elected to skip downloading step with -s. This will download all the results, which may be slow. Are you sure you want to continue? (Yes/No): ";
	my $line = <STDIN>;
	if ($line =~ m/^\s*y/i) {
	    $approved = 1;
	} elsif ($line =~ m/^\s*n/i) {
	    exit(1);
	}
    }
}

my $runner = ParsingRunner->new($downloader, $googleParser);

$runner->run($inputFile);

$googleParser->teardown();
