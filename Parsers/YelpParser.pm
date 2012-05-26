package YelpParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for yelp. Gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings
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
   
    return $url =~ m/yelp\.com/i;
}

sub outputFilename {
    return "yelpResults.txt";
}

sub pageName {
    return "Yelp";
}


sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $reviewElem = $tree->look_down('class', 'hReview-aggregate');

    if (!$reviewElem) {
	print STDERR "Bad Yelp page $path\n";
	return "--", "--";
    }

    my $nameElem = $reviewElem->look_down('class', 'fn org');
    my $fullName = $nameElem->as_text();

    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $ratingBlock = $tree->look_down('id', 'bizRating');
    my $rating = "--";
    my $ratingCount = 0;
    if ($ratingBlock) {
	my $ratingElem = $ratingBlock->look_down('class', 'rating average');
	if ($ratingElem) {
	    my $strRating = $ratingElem->attr('title');
	    $strRating =~ m/(\d+\.?\d*)/;
	    $rating = $1;
	    
	    my $outerCountElem = $ratingBlock->look_down('class', 'review-count');
	    my $countElem = $outerCountElem->look_down('class', 'count');
	    $ratingCount = $countElem->as_text();
	}
    }

    return $rating, $ratingCount;
}

1;
