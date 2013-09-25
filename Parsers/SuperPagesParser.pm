package SuperPagesParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for superpages.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, rating, number-of-ratings
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
   
    return $url =~ m/superpages\.com/i;
}

sub outputFilename {
    return "superPagesResults.txt";
}

sub pageName {
    return "Super Pages";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameOuterElem = $tree->look_down('id', 'coreBizName_nonad');
    if ($nameOuterElem) {
	my $nameElem = $nameOuterElem->look_down('_tag', 'h1');
	return ParserCommon::parseName($nameElem->as_text()) if $nameElem;
    }

    print STDERR "Bad SuperPages page $path\n";
    return "--", "--";
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = "--";

    my $ratingOuterElem = $tree->look_down('id', 'coreRating');
    if ($ratingOuterElem) {
	my $ratingElem = $ratingOuterElem->look_down('_tag', 'img');
	if ($ratingElem && $ratingElem->attr('alt') =~ m/(\d+\.?\d*) of 5/i) {
	    $rating = $1;
	}
    }

    my $ratingCountOuterElem = $tree->look_down('id', 'rdrwslnk');
    if ($ratingCountOuterElem) {
	my $ratingCountElem = $ratingCountOuterElem->look_down('_tag', 'strong');
	if ($ratingCountElem && $ratingCountElem->as_text() =~ m/(\d+) Review/i) {
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
    my $addrElem = $tree->look_down('id', 'coreBizAddress');
    if ($addrElem) {
	($city, $state, $zip) = ParserCommon::parseCityStateZip($addrElem->as_text());
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
