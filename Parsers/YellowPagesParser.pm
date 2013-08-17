package YellowPagesParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for yellowpages.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, rating, number-of-ratings, number-reviewed
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "City", "State", "Zip-Code", "Review-Rating", "Number-of-Ratings", "Number-Reviewed"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/yellowpages\.com/i;
}

sub outputFilename {
    return "yellowPagesResults.txt";
}

sub pageName {
    return "Yellow Pages";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameOuterElem = $tree->look_down('class', 'vcard item');
    if ($nameOuterElem) {
	my $nameElem = $nameOuterElem->look_down('_tag', 'a');
	if ($nameElem) {
	    my $name = $nameElem->as_text();
	    $name =~ s/\s+MD$//i; # Take of trailing MD
	    
	    # This name goes last name first name
	    my @nameParts = split(/\s+/, $name);
	    my $lastName = $nameParts[0];
	    my $firstName = "";
	    for (my $i = 1; $i < scalar(@nameParts); $i++) {
		$firstName .= $nameParts[$i] . " ";
	    }
	    $firstName =~ s/\s*$//;
	    return $firstName, $lastName;
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

    my $ratingElem = $tree->look_down('class', 'average-rating rating');
    if ($ratingElem && $ratingElem->as_text() =~ m/(\d+\.?\d*) stars/i) {
	$rating = $1;
    }

    my $ratingCountElem = $tree->look_down('id', 'average-rating-count');
    if ($ratingCountElem && $ratingCountElem->as_text() =~ m/(\d+) Ratings/i) {
	$ratingCount = $1;
    }
    return $rating, $ratingCount;
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;

    if (! -e $path) {
	print STDERR "Could not find requested path $path\n";
	return 0;
    }

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

    my $reviewCount = "--";
    my $reviewCountElem = $tree->look_down('class', 'count track-read-reviews');
    if ($reviewCountElem && $reviewCountElem->as_text() =~ m/(\d+) Reviews/i) {
	$reviewCount = $1;
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
    $output{"Number-Reviewed"} = $reviewCount;
    return %output;
}

1;
