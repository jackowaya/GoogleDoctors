package GoogleDownloader;
use ParsingFramework::FileDownloader;
@ISA = ("FileDownloader");
# Google downloader - Gets first two search pages and all their results.
# input path(s) sent to download method will be CSV files.
# output will go in a directory specified at create time. Output files are
# SN.1.html and SN.2.html (for search pages) and SN.1.NUM.html (for result pages).
# SN is taken from CSV file.

use strict;

use Text::CSV;
use HTML::Tree;
use HTML::TreeBuilder;
use WWW::Mechanize;
use URI::Escape;


sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{FILES} = [];
    
    $self->{SKIPDOWNLOAD} = shift;
    $self->{OUTPUTDIR} = shift;
    $self->{PAGES} = shift;

    bless($self, $class);
    return $self;
}

sub download {
    my $self = shift;
    if ($self->{SKIPDOWNLOAD}) {
	print "Downloading step was skipped\n";
	return;
    }
    my $i;
    my $myURI;
    my $filename;

    my $infile = shift;
    my $outfolder = $self->{OUTPUTDIR};

    my @doctorInfo = @{$self->readCSV($infile)};

    foreach my $docRef (@doctorInfo) {
	for ($i = 1; $i <= $self->{PAGES}; ++$i) {
	    my $done = 0;
	    $myURI = $self->generateSearchUri($docRef, $i);
	    my %doc = %$docRef;
	
	    $filename = "$outfolder/$doc{'sn'}.$i.html";
	    #$if 
	    my $subfolder = "$outfolder/$doc{'sn'}.$i";

	    # Get the first page and its links, then the next page, then pause.
	    $self->getSearchAndSubs($myURI, $filename, $subfolder, "$doc{'sn'}.$i");
	    sleep 15;
	}
	sleep 15;
    }

    print "done! Ta Da \n";

}

sub downloadPage {
    my $self = shift;
    my $url = shift;
    my $outfile = shift;

    my $mech = new WWW::Mechanize;
    eval {
	$mech->get($url);
	# for healthgrades, vitals, and ucompare changes url to page with more extensive ratings
	if($url =~ m/healthgrades\.com\/physician/i){
		$mech->follow_link( url_regex => qr/patient\-ratings/i );
	}elsif( $url =~ m/vitals.com\/doctors/i){
		if($mech->find_link( url_regex => qr/reviews/i )){
			$mech->follow_link( url_regex => qr/reviews/i );
		}
	}elsif( $url =~ m/ucomparehealthcare\.com\/drs/i){
		if($mech->find_link( url_regex => qr/reviews/i )){
			$mech->follow_link( url_regex => qr/reviews/i );
		}
	}
	$url = $mech->uri;	
	$mech->save_content($outfile);
	
	print "Wrote $url to $outfile\n";
    };
    if ($@) {
	print STDERR "ERROR Writing $url to $outfile: $@ - creating empty file\n";
	open(FO, ">" . $outfile);
	print FO "ERROR Downloading: $@\n";
	close(FO);
    }	
}

sub getSearchAndSubs {
    my $self = shift;
    my $url = shift;
    my $outfile = shift;
    my $subfolder = shift;
    my $subprefix = shift;
 
    $self->downloadPage($url, $outfile);

    mkdir $subfolder unless -d $subfolder;

    $self->getSubLinks($outfile, $subfolder, $subprefix);
}

sub outputPaths {
    my $self = shift;
    opendir(DIR, $self->{OUTPUTDIR});
    my @files = readdir(DIR);
    closedir(DIR);
    my @res;
    foreach my $file (@files) {
	if ($file !~ /^\.*$/) {
	    push(@res, $self->{OUTPUTDIR} . "/" . $file);
	}
    }
    return @res;
}

sub generateSearchUri {
    my $self = shift;
    my $docRef = shift;
	my %doc = %$docRef;
	my $page = shift;
	
	my $uri = URI->new("http://www.google.com/search");
	if ($page > 1) {
	    my $start = ($page - 1) * 10;
		$uri-> query_form(ie => "UTF-8", q => "$doc{'lastname'} $doc{'firstname'} $doc{'specialty'} $doc{'city'} $doc{'state'}", start => "$start");
	} else {
		$uri-> query_form(ie => "UTF-8", q => "$doc{'lastname'} $doc{'firstname'} $doc{'specialty'} $doc{'city'} $doc{'state'}");
	}
	return $uri;
}

sub getSubLinks {
    my $self = shift;
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
			$url =~ s/^\/url\?q=//;
			$url =~ s/&amp;sa=.*$//;
			$url =~ s/&sa=.*$//;
			$url = uri_unescape($url);
			
			$self->downloadPage($url, $outfile);

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
		$url = uri_unescape($url);
	
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
    my $self = shift;
	my $infile = shift;
	open(IN, "<$infile");
	my @results;
	my @lines = <IN>;
	close(IN);
	my $csv = Text::CSV->new();
	
	my @columnNames;
	if ($csv->parse($lines[0])) {
		@columnNames = $csv->fields();
		for (my $i = 0; $i < scalar(@columnNames); $i++) {
		    $columnNames[$i] = lc($columnNames[$i]);
		}
	
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
1;
