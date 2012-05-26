package YahooLocalParser;
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
   
    return $url =~ m/local\.yahoo\.com/i;
}

sub outputFilename {
    return "yahooLocalResults.txt";
}

sub pageName {
    return "Yahoo Local";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('id', 'HDN_title', );

    if (!$nameElem) {
	return "--", "--";
    }

    # These titles are of the form last, first MD - something
    # but parser common expects first last.
    my $fullName = $nameElem->as_text();

    $fullName =~ s/(?:MD)?\s*-.*$//;
    my @parts = split(/,/, $fullName);
    if (scalar(@parts) == 2) {
	$fullName = "$parts[1] $parts[0]";
    } else {
	print STDERR "Error in Yahoo parsing path $path with name $fullName\n";
    }

    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    # The last one that matches is the one we want.
    my $rating = "--";
    my $ratingCount = 0;

    my $ratingElem = $tree->look_down('id', 'HDN_reviewavg');
    if ($ratingElem) {
	$rating = $ratingElem->as_text();
    }

    my $countElem = $tree->look_down('id', 'HDN_reviewcnt');
    if ($countElem) {
	$ratingCount = $countElem->as_text();
    }
    
    return $rating, $ratingCount;
}

1;
