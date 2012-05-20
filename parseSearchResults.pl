#!/usr/bin/perl -w

#require 5;
use strict;
use warnings;

use HTML::Tree;
use HTML::TreeBuilder;

if (scalar(@ARGV) != 1) {
    print "Usage: parseSearchResults.pl outdir\n";
    print "\tGets all of the links from doctor search results by output directory of grabSearchResults. Prints them to STDOUT\n";
    exit;
}

print "ID\tResult Page\tResult Number\tLink\n";
my $infolder = $ARGV[0];

opendir(DIR, $infolder);
my @files = readdir(DIR);
closedir(DIR);

foreach my $file (@files) {
    if ($file =~ m/(\w+-\d+)\.(\d+)\.(\d+)/) {
		my $docId = $1;
		my $page = $2;
		my $res = $3;
		my @links = getSubLinks("$infolder/$file");
		
		foreach my $link (@links) {
			print "$docId\t$page\t$res\t$link\n";
		}
	}
}

sub getSubLinks {
	my $filename = shift;
	
	my $tree = HTML::Tree->new_from_file($filename);
	
	my @links = $tree->look_down('_tag', 'a');

	my @res;
	
	foreach my $link (@links) {
		my $url = $link->attr('href');
		#if ($url && $url ne "") {
		if ($url && $url =~ m/http/i) {
			push(@res, $url);
		}
	}
	
	return @res;
}

__END__



