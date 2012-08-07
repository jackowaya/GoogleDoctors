package InsiderPagesParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for insider pages. Gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings, Count_review, Count_patientsurvey
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-Rating", "Number-of-Ratings", "Count_review", "Count_patientsurvey"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/insiderpages\.com/i;
}

sub outputFilename {
    return "insiderPagesResults.txt";
}

sub pageName {
    return "Insider Pages";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameElem = $tree->look_down('class', 'org fn business_card_name');

    if (!$nameElem) {
	print STDERR "Bad InsiderPages page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();

    return ParserCommon::parseName($fullName);

}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $ratingBlock = $tree->look_down(sub {
	$_[0]->attr('class') eq 'rating_box' &&
	    !$_[0]->look_up('id', 'search_results')
				       });
    my $rating = "--";
    my $ratingCount = 0;
    if ($ratingBlock) {
	my $ratingElem = $ratingBlock->look_down('_tag', 'abbr');
	$rating = $ratingElem->attr('title') if $ratingElem;
	my $countElem = $ratingBlock->look_down('class', 'count');
	$ratingCount = $countElem->as_text() if $countElem;
    }

    return $rating, $ratingCount;
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;
    my $tree = HTML::Tree->new_from_file($path);
 
    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my ($rating, $ratingCount) = $self->getRatingFromTree($tree, $path);

    my ($googlePage, $googleResult) = $self->getGooglePage($path);

    my $reviewCount = 0;
    my $surveyCount = 0;
    my $reviewDetailsElem = $tree->look_down('class', 'review_explanation');
    if ($reviewDetailsElem && $reviewDetailsElem->as_text() =~ m/From (\d+) Review and (\d+) Patient Surveys/i) {
	$reviewCount = $1;
	$surveyCount = $2;
    }

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Google-Page"} = $googlePage;
    $output{"Google-Result"} = $googleResult;
    $output{"Review-LastName"} = $lastName;
    $output{"Review-FirstName"} = $firstName;
    $output{"Review-Rating"} = $rating;
    $output{"Number-of-Ratings"} = $ratingCount;
    $output{"Count_review"} = $reviewCount; 
    $output{"Count_patientsurvey"} = $surveyCount;
    return %output;
}


1;
