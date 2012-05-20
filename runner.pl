#! /usr/bin/perl 
# Main runner for google doctors. Downloads and parses files.

use strict;
use warnings;

use FindBin;
# TODO: Can we do this without putting it in site_perl?
use ParsingFramework::ParsingRunner;

use GoogleDownloader;
use GoogleParser

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

my $downloader = GoogleDownloader->new($skipDownload, shift @ARGV);
my $parser = GoogleParser->new($ARGV[1]);

my $runner = ParsingRunner->new($downloader, $parser);

$runner->run(shift @ARGV);

