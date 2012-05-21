package GoogleParser;

use ParsingFramework::FileParser;
use Parsers::RateMdsParser;
use Parsers::VitalsParser;
use Parsers::HealthGradesParser;
@ISA = ("FileParser");

# Google parser - Wraps several different parsers - one that gets the links
# from google search results and several others for specific pages.
# This parser actually ignores many of the paths sent to it by parse, preferring to
# Determine which files are interesting based on the search results pages.
# Results are written to a folder specified at create time.
# To use this, you must call init and teardown yourself

use strict;
use URI::Escape;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my $resultDir = shift;
    $self->{RESULTDIR} = $resultDir;
    $self->{INITED} = 0;
    $self->{SUBPARSERS} = {
	'ratemds' => RateMdsParser->new($resultDir),
	'vitals' => VitalsParser->new($resultDir),
	'healthgrades' => HealthGradesParser->new($resultDir)
    };
    bless($self, $class);
    return $self;
}

sub init() {
    # Initializes this parser and sub-parsers
    my $self = shift;

    open($self->{OUTHANDLE}, "> $self->{RESULTDIR}/searchResults.txt") or die "Could not open google search results $!";
    my $handle = $self->{OUTHANDLE};
    print $handle "ID\tResult Page\tResult Number\tLink\n";
    foreach my $k (keys(%{$self->{SUBPARSERS}})) {
	$self->{SUBPARSERS}->{$k}->init();
    }
    $self->{INITED} = 1;
}

sub teardown() {
    # Tears down this parser and sub-parsers.
    my $self = shift;
    close($self->{OUTHANDLE});
    foreach my $k (keys(%{$self->{SUBPARSERS}})) {
	$self->{SUBPARSERS}->{$k}->teardown();
    }
    $self->{INITED} = 0;
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $path = shift;
    my (%sponsoredCounts, %normalCounts); # docId -> count
    my $totalCount = 0;
    if ($path =~ m/(\w+\d+)\.(\d+)\.html/) {
	my $docId = $1;
	my $page = $2;
	
	#print "Parsing Google Search Page at $path\n";
	my @links = $self->getSearchLinks($path);
	
	# Alternates between a link and a yes/no indicating sponsored.
	for (my $i = 0; $i < scalar(@links); $i += 2) {
	    $totalCount++;
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
	    
	    my $handle = $self->{OUTHANDLE};
	    print $handle "$docId\t$page\t$resultNum\t$links[$i]\t$links[$i + 1]\n";

	    my $subparser = $self->getSubParser($links[$i]);
	    if ($subparser) {
		my $subpath = $path;
		$subpath =~ s/\.html$//;
		# Sponsored links were downloaded second even though they 
		# appear first.
		if ($links[$i] eq "Yes") {
		    $subpath .= ".$totalCount.html";
		} else {
		    my $count = $totalCount - $sponsoredCounts{$docId};
		    $subpath .= ".$count.html";
		}
		$subparser->parse($docId, $subpath);
	    }
	}
    }

}

sub getSubParser {
    my $self = shift;
    my $url = shift;

    if ($url =~ m/ratemds\.com/i) {
	return $self->{SUBPARSERS}->{'ratemds'};
    } elsif ($url =~ m/vitals\.com/i) {
	return $self->{SUBPARSERS}->{'vitals'};
    } elsif ($url =~ m/healthgrades\.com/i) {
	return $self->{SUBPARSERS}->{'healthgrades'};
    }

    return 0;
}

sub getSearchLinks {
    my $self = shift;
	my $filename = shift;
	
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
1;
