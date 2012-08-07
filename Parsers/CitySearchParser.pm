package CitySearchParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for CitySearch. Gets: doctorId, First Name, Last Name, Gender, City, Zip code, State, Review Score (1-5), Number of reviews
# NOTE: Currently not doing zip code or gender because we didn't have an example
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "First Name", "Last Name", "City", "State", "Review Score (1-5)", "Number of reviews"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/citysearch\.com/i;
}

sub outputFilename {
    return "citySearchResults.txt";
}

sub pageName {
    return "City Search";
}


sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('id', 'coreInfo.name');

    if (!$nameElem) {
	print STDERR "Bad CitySearch page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    # Full name like last, first, Md - place. Take off , MD - place
    $fullName =~ s/(?:, Md)?\s+-\s+.*?$//i;

    # Some full names don't have the commas or have the Md at the end
    $fullName =~ s/\s+Md\s*$//i;
    
    my @parts = split(/,/, $fullName);
    if (scalar(@parts) <= 1) {
	@parts = split(/\s+/, $fullName);
    }
    if (scalar(@parts) <= 1) {
	print STDERR "Could not process citysearch name " . $nameElem->as_text() . "\n";
	push(@parts, "");
	push(@parts, "");
    }
    my $lastName = $parts[0];
    $lastName =~ s/\s+$//;
    my $firstName = $parts[1];
    $firstName =~ s/^\s+//;
    $firstName =~ s/\s+$//;
    return $firstName, $lastName;
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $ratingBlock = $tree->look_down('class', 'ratingcard row');
    my $rating = "--";
    my $ratingCount = 0;
    if ($ratingBlock) {
	my $ratingOuterElem = $ratingBlock->look_down('class', 'ratingCardRatingEdge');
	if ($ratingOuterElem) {
	    my $ratingElem = $ratingOuterElem->look_down('_tag', 'strong');
	    $rating = $ratingElem->as_text() if $ratingElem;
	}
	
	my $countElem = $ratingBlock->look_down('id', 'reviewsCount');
	$ratingCount = $countElem->as_text() if $countElem;	
	if ($ratingCount =~ m/(\d+)/) {
	    $ratingCount = $1;
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

    my $city = "";
    my $cityElem = $tree->look_down('class', 'locality');
    $city = $cityElem->as_text() if $cityElem;

    my $state = "";
    my $stateElem = $tree->look_down('class', 'region');
    $state = $stateElem->as_text() if $stateElem;

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Google-Page"} = $googlePage;
    $output{"Google-Result"} = $googleResult;
    $output{"Last Name"} = $lastName;
    $output{"First Name"} = $firstName;
    $output{"Review Score (1-5)"} = $rating;
    $output{"Number of reviews"} = $ratingCount;
    $output{"City"} = $city;
    $output{"State"} = $state;
    return %output;
}

1;
