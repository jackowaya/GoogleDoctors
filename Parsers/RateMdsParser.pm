package RateMdsParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for ratemds.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings
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
   
    return $url =~ m/ratemds\.com/i;
}

sub outputFilename {
    return "rateMdsResults.txt";
}

sub pageName {
    return "RateMds";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('class', 'fn');

    if (!$nameElem) {
	print STDERR "Bad RateMds page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $rating = "--";
    my $ratingCount = 0;
    # RateMds Redesigned their site in August 2013. Try this one first
    my $ratingOuterElem = $tree->look_down('_tag', 'span', 'class', "rating");
    if ($ratingOuterElem) {
    	my $ratingElem = $ratingOuterElem->look_down('class', 'average');
	$rating = $ratingElem->as_text() if $ratingElem;
    
    	my $countElem = $ratingOuterElem->look_down('class', 'count');
 	$ratingCount = $countElem->as_text() if $countElem;
    
	return $rating, $ratingCount;
    }

    # RateMds redesigned their site in November 2012. Try the new one first
    $ratingOuterElem = $tree->look_down('_tag', 'p', 'class', 'rating');
    if ($ratingOuterElem) {
    	my $ratingElem = $ratingOuterElem->look_down('class', 'average');
	$rating = $ratingElem->as_text() if $ratingElem;
    
    	my $countElem = $ratingOuterElem->look_down('class', 'count');
 	$ratingCount = $countElem->as_text() if $countElem;
    
	return $rating, $ratingCount;
    }

    # The last one that matches is the one we want.
    my @ratingRows = $tree->look_down(sub {
         $_[0]->tag() eq 'tr' &&
         $_[0]->as_text() =~ m/Overall\s+Quality\*/
    });
    my $ratingRow = pop(@ratingRows);

    if ($ratingRow) {
	# May not have ratings yet.
	my @ratingRowCells = $ratingRow->look_down('_tag', 'td');
	$rating = $ratingRowCells[2]->as_text();
    }

    # The last one that matches is the one we want.
    my @countRows = $tree->look_down(sub {
         $_[0]->tag() eq 'tr' &&
         $_[0]->as_text() =~ m/#\s+Ratings/
    });
    my $countRow = pop(@countRows);

    if ($countRow) {
	# May not have ratings yet.
	my @countRowCells = $countRow->look_down('_tag', 'td');
	$ratingCount = $countRowCells[2]->as_text();
    }
    
    return $rating, $ratingCount;
}

1;
