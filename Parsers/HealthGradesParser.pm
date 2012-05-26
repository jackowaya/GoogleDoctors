package HealthGradesParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for healthgrades.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating, Number-of-ratings
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
   
    return $url =~ m/healthgrades\.com/i;
}

sub outputFilename {
    return "healthGradesResults.txt";
}

sub pageName {
    return "Health Grades";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameSection = $tree->look_down('id', 'physician-name-h1');

    if (!$nameSection) {
	print STDERR "Bad health grades page $path\n";
	return "--", "--";
    }

    my $fullName = $nameSection->as_text();
    $fullName =~ s/^\s*Dr\.\s*//;
    return ParserCommon::parseName($fullName);

}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $ratingSection = $tree->look_down('id', 'overallPatientRating');
    my $rating = "--";
    my $ratingCount = 0;

    if ($ratingSection) {
	my $ratingElem = $ratingSection->look_down('class', 'value');
	$rating = $ratingElem->as_text();

	my $countElem = $ratingSection->look_down('class', 'votes');
	$ratingCount = $countElem->as_text();
    }

    return $rating, $ratingCount;
}

1;
