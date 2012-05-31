package VitalsParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for vitals.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

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
	    print STDERR "Bad vitals page $path\n";
	    return "--", "--";
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


1;
