#!/usr/bin/perl -w

#require 5;
use strict;
use warnings;

use HTML::Tree;
use HTML::TreeBuilder;

if (scalar(@ARGV) != 1) {
    print "Usage: parseSearchResultsExternal.pl outdir\n";
    print "\tGets all of the external links from doctor search results by output directory of grabSearchResults. Prints them to STDOUT\n";
    exit;
}

print "ID\tResult Page\tResult Number\tLink\n";
my $infolder = $ARGV[0];

opendir(DIR, $infolder);
my @files = readdir(DIR);
closedir(DIR);

foreach my $file (@files) {
    if ($file =~ m/(\w+-\d+)\.(\d+)\.html/) {
		my $docId = $1;
		my $page = $2;
		my @googleLinks = getSubLinks("$infolder/$file");
		
		for (my $i = 0; $i < scalar(@googleLinks); $i++) {
			my $cnt = $i + 1;
			my $domain = getDomain($googleLinks[$i]);
			
			my @links = getExternalLinks("$infolder/$docId.$page.$cnt.html", $domain);
			
			foreach my $link (@links) {
				print "$docId\t$page\t$cnt\t$link\n";
			}
		}
	}
}

sub getDomain {
	my $url = shift;
	
	# This was wrong
	#if ($url =~ /https?:\/\/[^\/]*([^\.]+\.[^\.]+)\//) {
	$url =~ s#^https?://##;
	my @parts = split(/\//, $url);
	
	if ($parts[0] =~ m/([^\.]+\.[^\.]+)$/) {
		return $1;
	} else {
		die "Couldn't get domain from $url";
	}
}

sub getSubLinks {
	my $filename = shift;
	
	my $tree = HTML::Tree->new_from_file($filename);
	
	my $googleResults = $tree->look_down('id', 'res');
	my @resultHeaders = $googleResults->look_down('class', 'r');
	print "result headers: " . scalar(@resultHeaders) . "\n";
	my $cnt = 1;
	
	my @res;
	foreach my $resHeader (@resultHeaders) {
		my @links = $resHeader->look_down('_tag', 'a');
		
		foreach my $link (@links) {
			my $url = $link->attr('href');
			push (@res, $url);
		}
	}
	return @res;
}

sub getExternalLinks {
	my $filename = shift;
	my $domain = shift;
	
	my $tree = HTML::Tree->new_from_file($filename);
	
	my @links = $tree->look_down('_tag', 'a');

	my @res;
	
	foreach my $link (@links) {
		my $url = $link->attr('href');
		#if ($url && $url ne "") {
		if ($url && $url =~ m/http/i && $url !~ m/$domain/) {
			push(@res, $url);
		}
	}
	
	return @res;
}

__END__



