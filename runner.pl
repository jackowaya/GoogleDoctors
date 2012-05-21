#! /usr/bin/perl 
# Main runner for google doctors. Downloads and parses files.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/..";
use ParsingFramework::ParsingRunner;

use GoogleDownloader;
use GoogleParser;

my $usage = "Usage runner.pl [-s|--skip-download] input-path download-path results-path\n";

if (scalar(@ARGV) == 0) {
    print $usage;
    exit(0);
}

my $skipDownload = 0;
if ($ARGV[0] eq "-s" || $ARGV[0] eq "--skip-download") {
    $skipDownload = 1;
    shift @ARGV;
}

if (scalar(@ARGV) != 3) {
    print $usage;
    exit(0);
}

my $inputFile = shift @ARGV;
my $downloader = GoogleDownloader->new($skipDownload, shift @ARGV);
my $parser = GoogleParser->new(shift @ARGV);
$parser->init();

my $runner = ParsingRunner->new($downloader, $parser);

$runner->run($inputFile);

$parser->teardown();
