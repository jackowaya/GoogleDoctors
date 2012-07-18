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
	# Try another type of yelp page.
	$reviewElem = $tree->look_down('id', 'bizInfoHeader');
	if (!$reviewElem) {
	    print STDERR "Bad Yelp page $path\n";
	    return "--", "--";
	}
	my $nameElem = $reviewElem->look_down(sub {
	    $_[0]->tag() eq 'h1' && $_[0]->attr('itemprop') eq 'name'});
	if (!$nameElem) {
	    print STDERR "Bad Yelp page $path (No name)\n";
	    return "--", "--";
	}
	my $fullName = $nameElem->as_text();
	$fullName =~ s/\s*MD$//i;
	return ParserCommon::parseName($nameElem->as_text());
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
	} else {
	    # Another type of yelp page.
	    my $ratingElem = $ratingBlock->look_down(sub {
		$_[0]->tag() eq 'img' && $_[0]->attr('title') =~ m/star rating/});
	    if ($ratingElem) {
		$rating = $ratingElem->attr('title');
		$rating =~ s/\s*star rating\s*//i;
	    }
	    my $countElem = $tree->look_down(sub {
		$_[0]->tag() eq 'span' && $_[0]->attr('itemprop') eq 'reviewCount'});
	    if ($countElem) {
		$ratingCount = $countElem->as_text();
	    }
	}
    } 

    return $rating, $ratingCount;
}

1;
