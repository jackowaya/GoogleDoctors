package ZocDocParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for zocdoc.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, rating, number-of-ratings
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
   
    return $url =~ m/zocdoc\.com/i;
}

sub outputFilename {
    return "zocDocResults.txt";
}

sub pageName {
    return "ZocDoc";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameElem = $tree->look_down('class', 'docLongName');
    return ParserCommon::parseName($nameElem->as_text()) if $nameElem;
	
    print STDERR "Bad ZocDoc page $path\n";
    return "--", "--";
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = "--";

    my $ratingElem = $tree->look_down('_tag', 'meta', 'itemprop', 'ratingValue');
    $rating = $ratingElem->attr('content') if $ratingElem;

    my $ratingCountElem = $tree->look_down('_tag', 'meta', 'itemprop', 'ratingCount');
    $ratingCount = $ratingCountElem->attr('content') if $ratingCountElem;

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
    my $cityElem = $tree->look_down('_tag', 'span', 'itemprop', 'addressLocality');
    $city = $cityElem->as_text() if $cityElem;
    my $stateElem = $tree->look_down('_tag', 'span', 'itemprop', 'addressRegion');
    $state = $stateElem->as_text() if $stateElem;
    my $zipElem = $tree->look_down('_tag', 'span', 'itemprop', 'postalCode');
    $zip = $zipElem->as_text() if $zipElem;

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
