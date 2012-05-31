package GoogleMapsParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for maps.google.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $resultDir = shift;
    my $self = $class->SUPER::new($resultDir);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/maps\.google\.com/i;
}

sub outputFilename {
    return "googleMapsResults.txt";
}

sub pageName {
    return "Google Maps";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('class', 'pp-place-title');

    if (!$nameElem) {
	print STDERR "Bad Google Maps page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $ratingBlock = $tree->look_down('id', 'pp-reviews-headline');
    
    my $rating = "--";
    my $ratingCount = 0;
    if ($ratingBlock) {
	my $ratingElem = $ratingBlock->look_down('class', 'rsw-stars ');
	if ($ratingElem) {
	    $rating = $ratingElem->attr('g:rating_override');
	}	

	my $outerCountElem = $ratingBlock->look_down('class', 'rsw-pp rsw-pp-link');
	if ($outerCountElem) {
	    my @spans = $outerCountElem->look_down('_tag', 'span');
	    # want first span
	    $ratingCount = $spans[0]->as_text();
	    $ratingCount =~ s/\s*reviews\s*//;
	}
    }

    return $rating, $ratingCount;
}

1;
