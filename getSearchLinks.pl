#!/usr/bin/perl -w

#require 5;
use strict;
use warnings;

use HTML::Tree;
use HTML::TreeBuilder;
use URI::Escape;

if (scalar(@ARGV) != 1) {
    print "Usage: getSearchLinks.pl outdir\n";
    print "\tGets all of the google links from doctor search results by output directory of grabSearchResults. Prints them to STDOUT\n";
    exit;
}

print "ID\tResult Page\tResult Number\tLink\tSponsored\n";
my $infolder = $ARGV[0];

opendir(DIR, $infolder);
my @files = readdir(DIR);
closedir(DIR);

foreach my $file (@files) {
    #if ($file =~ m/(\w+-\d+)\.(\d+)\.html/) {
	my (%sponsoredCounts, %normalCounts); # docId -> count
	if ($file =~ m/(\w+\d+)\.(\d+)\.html/) {
		my $docId = $1;
		my $page = $2;
		
		my @links = getSearchLinks("$infolder/$file");

		# Alternates between a link and a yes/no indicating sponsored.
		for (my $i = 0; $i < scalar(@links); $i += 2) {
			my $resultNum;
			if ($links[$i + 1] eq "Yes") {
				if (defined($sponsoredCounts{$docId})) {
					$resultNum = $sponsoredCounts{$docId} + 1;
				} else {
					$resultNum = 1;
				}
				$sponsoredCounts{$docId} = $resultNum;
			} else {
				if (defined($normalCounts{$docId})) {
					$resultNum = $normalCounts{$docId} + 1;
				} else {
					$resultNum = 1;
				}
				$normalCounts{$docId} = $resultNum;
			}

			print "$docId\t$page\t$resultNum\t$links[$i]\t$links[$i + 1]\n";
		}
	}

}

sub getSearchLinks {
	my $filename = shift;
	my $outfolder = shift;
	my $filePrepend = shift;
	
	my $tree = HTML::Tree->new_from_file($filename);
	my @results;
	
	# Sponsored links come first
	my $cnt = 1;
	while (my $link = $tree->look_down('id', "pa$cnt")) {
		my $fullUrl = $link->attr('href');
		# fullURL looks like this:
		# /aclk?sa=L&amp;ai=C7H3EyL42T5X0CYWi0AGzj8WiCLugwZ4Cw9nC7BfYs6xCCAAQAVC-9-Hp-f____8BYMmGo4fUo4AQyAEBqgQfT9ASt1Qo7KlAvC6f1cdNJrciPPhd-MklbDbcJNh29w&amp;sig=AOD64_02y7Zhs3jnLMjHIys-RInzAMyBeA&amp;adurl=http://cust1537.bidcenter-29.superpages.com/520245/urologist/Google-Myron%2BI%2BMurdoch%2BMd%2BLlc%3Fsource%3Dsearch%26creative%3D6309098707%26keyword%3Durologist
		# We need to cut off everything but the adurl property.
		my $url = $fullUrl;
		$url =~ s/^.*adurl=//i;
		$url = uri_unescape($url);
	
		push(@results, $url, "Yes");
		$cnt++;
	}
	
	# Now regular links
	my $googleResults = $tree->look_down('id', 'res');
	my @resultHeaders = $googleResults->look_down('class', 'r');
	
	foreach my $resHeader (@resultHeaders) {
		my @links = $resHeader->look_down('_tag', 'a');
		
		foreach my $link (@links) {
			my $url = $link->attr('href');
			
			$url =~ s/^\/url\?q=//;
			$url = uri_unescape($url);
			
			push(@results, $url, "No");
		}
	}
	
	return @results;
	
}
__END__



