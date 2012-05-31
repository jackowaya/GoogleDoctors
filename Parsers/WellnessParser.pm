package WellnessParser;
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
   
    return $url =~ m/wellness\.com/i;
}

sub outputFilename {
    return "wellnessResults.txt";
}

sub pageName {
    return "Wellness";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $vcardElem = $tree->look_down('class', 'marginBottom item vcard');

    if (!$vcardElem) {
	print STDERR "Bad Wellness page $path\n";
	return "--", "--";
    }

    my $nameElem = $vcardElem->look_down('class', 'fn');
    if ($nameElem) {
	my $fullName = $nameElem->as_text();
	
	return ParserCommon::parseName($fullName);
    } else {
	print STDERR "Differently bad Wellness page $path\n";
	return "--", "--";
    }
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $ratingBlock = $tree->look_down(sub {
	$_[0]->tag() eq 'div' &&
	    $_[0]->attr('class') eq 'details clear marginBottom' &&
	    $_[0]->as_text() =~ m/Add a review/i
				       });
    my $rating = "--";
    my $ratingCount = 0;
    if (!$ratingBlock) {
	return $rating, $ratingCount;
    }

    my $countElem = $ratingBlock->look_down('class', 'count');
    if ($countElem) {
	$ratingCount = $countElem->as_text();
    }

    my $outsideScoreElem = $ratingBlock->look_down('class', 'rating');
    if ($outsideScoreElem) {
	my $scoreElem = $outsideScoreElem->look_down('class', 'value-title');
	$rating = $scoreElem->attr('title');
    }

    return $rating, $ratingCount;
}

1;
