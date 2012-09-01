package YellowBotParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for yellowbot.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, rating, number-of-ratings, number-recommended, number-not-recommended
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "City", "State", "Zip-Code", "Review-Rating", "Number-of-Ratings", "Number-Recommended", "Number-Not-Recommended"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/yellowbot\.com/i;
}

sub outputFilename {
    return "yellowBotResults.txt";
}

sub pageName {
    return "Yellow Bot";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameOuterElem = $tree->look_down('class', 'location-info');
    if ($nameOuterElem) {
	my $nameElem = $nameOuterElem->look_down('_tag', 'h1');
	if ($nameElem) {
	    my $name = $nameElem->as_text();
	    # These often begin with a location -
	    $name =~ s/^[^-]+-\s*//;
	    return ParserCommon::parseName($name);
	}
    }

    print STDERR "Bad YellowBot page $path\n";
    return "--", "--";
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = "--";

    my $ratingOuterElem = $tree->look_down('class', 'stars');
    if ($ratingOuterElem) {
	my $ratingElem = $ratingOuterElem->look_down('class', 'rating');
	$rating = $ratingElem->as_text() if $ratingElem;

	my $ratingCountElem = $ratingOuterElem->look_down(sub {
	    $_[0]->tag() eq "dd" && $_[0]->attr('class') eq ''
							  });
	if ($ratingCountElem) {
	    $ratingCount = $ratingCountElem->as_text();
	    # Get rid of parentheses or other bad characters
	    $ratingCount =~ s/\D//g;
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

    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my ($rating, $ratingCount) = $self->getRatingFromTree($tree, $path);

    my ($googlePage, $googleResult) = $self->getGooglePage($path);

    my ($city, $state, $zip);
    $city = $state = $zip = "--";
    my $cityElem = $tree->look_down('class', 'locality');
    $city = $cityElem->as_text() if $cityElem;
    my $stateElem = $tree->look_down('class', 'region');
    $state = $stateElem->as_text() if $stateElem;
    my $zipElem = $tree->look_down('class', 'postal-code');
    $zip = $zipElem->as_text() if $zipElem;

    my ($recommended, $notRecommended);
    $recommended = $notRecommended = "--";
    my $recommendationElem = $tree->look_down('class', 'recommendation');
    if ($recommendationElem) {
	my $yesOuterElem = $recommendationElem->look_down(sub {
	    $_[0]->tag() eq 'a' && $_[0]->attr('class') =~ m/yes/i
							  });
	if ($yesOuterElem) {
	    my $yesElem = $yesOuterElem->look_down('_tag', 'em');
	    $recommended = $yesElem->as_text() if $yesElem;
	}

	my $noOuterElem = $recommendationElem->look_down(sub {
	    $_[0]->tag() eq 'a' && $_[0]->attr('class') =~ m/no/i
							  });
	if ($noOuterElem) {
	    my $noElem = $noOuterElem->look_down('_tag', 'em');
	    $notRecommended = $noElem->as_text() if $noElem;
	}
    }

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Google-Page"} = $googlePage;
    $output{"Google-Result"} = $googleResult;
    $output{"Review-LastName"} = $lastName;
    $output{"Review-FirstName"} = $firstName;
    $output{"Review-Rating"} = $rating;
    $output{"Number-of-Ratings"} = $ratingCount;
    $output{"City"} = $city;
    $output{"State"} = $state;
    $output{"Zip-Code"} = $zip;
    $output{"Number-Recommended"} = $recommended;
    $output{"Number-Not-Recommended"} = $notRecommended;
    return %output;
}

1;
