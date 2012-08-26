package BookHealthcareParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for bookhealthcare.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, rating, number-of-ratings
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "City", "State", "Zip-Code", "Review-Rating", "Number-of-Ratings"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/bookhealthcare\.com/i;
}

sub outputFilename {
    return "bookHealtcareResults.txt";
}

sub pageName {
    return "Book Healthcare"
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameOuterSection = $tree->look_down('class', 'doc-info-left');
    if ($nameOuterSection) {
	my $nameElem = $nameOuterSection->look_down('_tag', 'h2');
	
	return ParserCommon::parseName($nameElem->as_text());
    }
	
    print STDERR "Bad Book Healthcare page $path\n";
    return "--", "--";
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = 0;
    my $reviewSection = $tree->look_down('class', 'ratings');
    if ($reviewSection) {
	my $ratingElem = $reviewSection->look_down('_tag', 'img');
	$rating = $ratingElem->attr('alt') if $ratingElem;

	my $countElem = $reviewSection->look_down('_tag', 'div');
	if ($countElem && $countElem->as_text() =~ m/Reviews (\d+)/i) {
	    $ratingCount = $1;
	}
    } else {
	print STDERR "No rating found in Book Healthcare page $path\n";
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
    my $docInfoSection = $tree->look_down('class', 'doc-info-left');
    if ($docInfoSection) {
	my $addrElem = $docInfoSection->look_down('_tag', 'p');
	if ($addrElem) {
	    my @parts = split(/\<br \/\>/, $addrElem->as_HTML());
	    ($city, $state, $zip) = ParserCommon::parseCityStateZip($parts[1]);
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
    return %output;
}

1;
