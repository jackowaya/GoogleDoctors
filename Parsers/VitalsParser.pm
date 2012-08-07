package VitalsParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for vitals.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(shift);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/vitals\.com/i;
}

sub outputFilename {
    return "vitalsResults.txt";
}

sub pageName {
    return "Vitals"
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $reviewSection = $tree->look_down('id', 'review_section');
    if (!$reviewSection) {
	# There is another type of vitals page that doesn't have review_section.
	my $nameSection = $tree->look_down('class', 'vcard rate');
	if (!$nameSection) {
	    # There is another type of page that doesn't have this.
	    my $vcardSection = $tree->look_down('class', 'vcard');
	    if (!$vcardSection) {
		print STDERR "Bad vitals page $path\n";
		return "--", "--";
	    }
	    my $vcardText = $vcardSection->as_text();
	    if ($vcardText =~ m/(.*) is a/i) {
		my $name = $1;
		$name =~ s/Dr\.\s*//i;
		return ParserCommon::parseName($name);
	    } else {
		print STDERR "Bad vitals page $path\n";
		return "--", "--";
	    }
	}
	my $nameElem = $nameSection->look_down('_tag', 'h1', 'class', 'fn txtOrangeL');
	my $fullName = $nameElem->as_text();
	
	return ParserCommon::parseName($fullName);

    }
	
    my $nameSection = $reviewSection->look_down('_tag', 'h2');

    my $fullName = $nameSection->as_text();
    $fullName =~ s/\s+Doctor\s+Ratings\s*$//;
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = 0;
    my $reviewSection = $tree->look_down('id', 'review_section');
    if (!$reviewSection) {
	# There is another type of vitals page that doesn't have review_section.
	
	my $overallRatingImg = $tree->look_down(sub {
	    $_[0]->tag() eq 'img' &&
		$_[0]->attr('src') =~ m/r_stars\d\.\d\.gif/i
						});
	if (!$overallRatingImg) {
	    # There is another type of vitals page that doesn't have this image either.
	    my $ratingSection = $tree->look_down('class', 'hreview-aggregate');
	    # There is another another type of vitals page that has the same text as this but
	    # in a different div.
	    if (!$ratingSection) {
		print STDERR "Bad Vitals page $path\n";
	    }
	    if ($ratingSection && $ratingSection->as_text() =~ m/has been reviewed by (\d+) patients?. The rating is (\d+\.?\d*)/i) {
		$rating = $2;
		$ratingCount = $1;
	    }

	    return $rating, $ratingCount;
	}

	$overallRatingImg->attr('src') =~ m/r_stars(\d\.\d)\.gif/i;
	$rating = $1;

	my $summaryDiv = $tree->look_down('id', 'summary_container');
	if ($summaryDiv) {
	    my $numRatingsSpan = $summaryDiv->look_down('class', 'count');
	    $ratingCount = $numRatingsSpan->as_text() if $numRatingsSpan;
	}
    } else {
	my $ratingSection = $reviewSection->look_down('class', 'value');
	$rating = $ratingSection->as_text();

	my $countSection = $reviewSection->look_down(sub {
	    $_[0]->tag() eq 'p' &&
		$_[0]->as_text() =~ m/Based on \d+ Ratings/i
						     });
	if ($countSection) {
	    $countSection->as_text() =~ m/Based on (\d+) Ratings/i;
	    $ratingCount = $1;
	}
    }

    return $rating, $ratingCount;
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;

    my $tree = HTML::Tree->new_from_file($path);

    if ($tree->look_down('class', 'cityspec_overview')) {
	# We got a search page, so we need to download another one.
	my $outputPath = $path;
	$outputPath =~ s/\/\//\//g;
	$outputPath =~ m/([^\/]*)$/;
	my $filePart = $1;
	$outputPath =~ s/[^\/]*$//;
	my $downloadedDir = $outputPath;
	$outputPath .= "vitals";
	mkdir $outputPath unless -d $outputPath;
	$outputPath .= "/" . $filePart;

	# Look at the parent downloaded page to get which doctor we searched for.
	my $parentDir = $downloadedDir;
	$parentDir =~ s/[^\/]*\/$//;
	my $parentFileName = $filePart;
	# Need to cut off the last .something before the .html
	$parentFileName =~ s/\d+\.html/html/;
	my $parentPath = "$parentDir/$parentFileName";
	if (-e $parentPath) {
	    my $parentTree = HTML::Tree->new_from_file($parentPath);
	    # Get the first word of the search.
	    my $titleElem = $parentTree->look_down('_tag', 'title');
	    if ($titleElem) {
		my $title = $titleElem->as_text();
		if ($title =~ /^(\w+)/) {
		    my $searchName = $1;
		    my $link = $tree->look_down(sub {
			$_[0]->tag() eq 'a' &&
			    $_[0]->attr('title') eq 'doctor_name' &&
			    $_[0]->as_text =~ m/$searchName/i
						});
		    if ($link) {
			my $url = $link->attr('href');
	    
			my $content = get($url);
	    
			open(FO, ">$outputPath") or die "Could not open $outputPath $!";
			print FO $content;
			close(FO);

			return $self->SUPER::getDataFields($doctorId, $outputPath);
		    } else {
			print STDERR "Didn't find link for $searchName in $parentPath\n";
		    }
		} else { 
		    print STDERR "Empty title in $parentPath\n";
		}
	    } else {
		print STDERR "No title in $parentPath\n";
	    }
	} else {
	    print STDERR "Didn't find parent for bad vitals page $path (parent should be $parentPath)\n";
	}
    }

    return $self->SUPER::getDataFields($doctorId, $path);
}

1;
