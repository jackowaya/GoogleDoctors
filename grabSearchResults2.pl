#!/usr/bin/perl -w

# Example code from Chapter 1 of /Perl and LWP/ by Sean M. Burke
# http://www.oreilly.com/catalog/perllwp/
# sburke@cpan.org

#require 5;
use strict;
#use warnings;

use Text::CSV;
use LWP::Simple;
use HTML::Tree;
use HTML::TreeBuilder;
use WWW::Mechanize
my $i;
my $myURI;
my $filename;

if (scalar(@ARGV) != 2) {
    print "Usage: grabSearchResults.pl filename outdir\n";
    print "\tGet doctor search results by input csv file and output directory\n";
    exit;
}

my $infile = $ARGV[0];
my $outfolder = $ARGV[1];

my @doctorInfo = @{readCSV($infile)};
# foreach my $docRef (@doctorInfo) {
	# my %docs = %$docRef;
	
	# foreach my $key (keys(%docs)) {
		# print "$key -> $docs{$key}\t";
	# }
	# print "\n";
# }

foreach my $docRef (@doctorInfo) {
    my $cnt = 0;

    my $done = 0;
    $myURI = generateSearchUri($docRef, 1);
	my %doc = %$docRef;
	
	$filename = "$outfolder/$doc{'sn'}.1.html";
	
	# Get the first page and its links, then the next page, then pause.
	#open(FO, ">" . $filename) or die "Cannot open file $filename $!";
		
	#my $content = get($myURI);
	my $mech = new WWW::Mechanize;
	$mech->get($myURI);
		
	$mech->save_content($filename);
		
	print "Wrote $myURI to $filename\n";
	#close(FO);

	#getSubLinks($filename, $outfolder, "$doc{'serial'}.1");
	sleep 15;
	
	# second page!
	$myURI = generateSearchUri($docRef, 2);
	
	$mech = new WWW::Mechanize;
	$filename = "$outfolder/$doc{'sn'}.2.html";
	
	# Get the first page and its links, then the next page, then pause.
	#open(FO, ">" . $filename) or die "Cannot open file $filename $!";
		
	#$content = get($myURI);
	$mech->get($myURI);	
	#print FO $content;
	$mech->save_content($filename);
		
	print "Wrote $myURI to $filename\n";
	#close(FO);

	#getSubLinks($filename, $outfolder, "$doc{'sn'}.2");
	
	sleep 30;
}

print "done! Ta Da \n";

sub generateSearchUri {
	my $docRef = shift;
	my %doc = %$docRef;
	my $page = shift;
	
	my $uri = URI->new("http://www.google.com/search");
	if ($page == 2) {
		#$uri-> query_form(ie => "UTF-8", q => "$doc{'lastname'} $doc{'firstname'} $doc{'Specialty'} $doc{'city'} $doc{'state'}", start => "10");
		$uri-> query_form(ie => "UTF-8", q => "$doc{'lastname'} $doc{'firstname'} $doc{'specialty'} $doc{'state'}", start => "10");
	} else {
		#$uri-> query_form(ie => "UTF-8", q => "$doc{'lastname'} $doc{'firstname'} $doc{'Specialty'} $doc{'city'} $doc{'state'}");
		$uri-> query_form(ie => "UTF-8", q => "$doc{'lastname'} $doc{'firstname'} $doc{'specialty'} $doc{'state'}");
	}
	return $uri;
}

sub getSubLinks {
	my $filename = shift;
	my $outfolder = shift;
	my $filePrepend = shift;
	
	my $tree = HTML::Tree->new_from_file($filename);
	
	my $googleResults = $tree->look_down('id', 'res');
	my @resultHeaders = $googleResults->look_down('class', 'r');
	print "result headers: " . scalar(@resultHeaders) . "\n";
	my $cnt = 1;
	
	foreach my $resHeader (@resultHeaders) {
		my @links = $resHeader->look_down('_tag', 'a');
		
		my $outfile = "$outfolder/$filePrepend.$cnt.html";
		
		foreach my $link (@links) {
			my $url = $link->attr('href');
			open(FO, ">" . $outfile) or die "Cannot open file $outfile $!";
			
			my $content = get($url);
				
			print FO $content;
				
			print "Wrote $url to $outfile\n";
			close(FO);
			$cnt++;
			sleep 1;
		}
	}
	
	# Now, grab sponsored links
	$cnt = 1;
	while (my $link = $tree->look_down('id', 'pa$cnt')) {
		my $fullUrl = $link->attr('href');
		# fullURL looks like this:
		# /aclk?sa=L&amp;ai=C7H3EyL42T5X0CYWi0AGzj8WiCLugwZ4Cw9nC7BfYs6xCCAAQAVC-9-Hp-f____8BYMmGo4fUo4AQyAEBqgQfT9ASt1Qo7KlAvC6f1cdNJrciPPhd-MklbDbcJNh29w&amp;sig=AOD64_02y7Zhs3jnLMjHIys-RInzAMyBeA&amp;adurl=http://cust1537.bidcenter-29.superpages.com/520245/urologist/Google-Myron%2BI%2BMurdoch%2BMd%2BLlc%3Fsource%3Dsearch%26creative%3D6309098707%26keyword%3Durologist
		# We need to cut off everything but the adurl property.
		my $url = $fullUrl;
		$url =~ s/^.*&amp;adurl=//i;
	
		my $outfile = "$outfolder/$filePrepend.sponsored.$cnt.html";
		open(FO, ">" . $outfile) or die "cannot open file $outfile: $!";
		
		my $content = get($url);
		print FO $content;
		
		print "Wrote $url to $outfile\n";
		
		close(FO);
		$cnt++;
	}
}

sub readCSV {
	my $infile = shift;
	open(IN, "<$infile");
	my @results;
	my @lines = <IN>;
	close(IN);
	my $csv = Text::CSV->new();
	
	my @columnNames;
	if ($csv->parse($lines[0])) {
		@columnNames = $csv->fields();
		
		for (my $i = 1; $i < scalar(@lines); $i++) {
			if ($csv->parse($lines[$i])) {
				my @cols = $csv->fields();
				my %output;
				for (my $j = 0; $j < scalar(@cols); $j++) {
					$output{$columnNames[$j]} = $cols[$j];
				}
				push(@results, \%output);
			} else {
				my $err = $csv->error_input;
				print "Failed to parse line: $err";
			}
		}
		
	} else {
		 my $err = $csv->error_input;
         print "Failed to parse line: $err";
	}
	
	return \@results;
}

__END__



