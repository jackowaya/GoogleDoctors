package KudzuParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for kudzu.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, rating, number-of-ratings
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
   
    return $url =~ m/kudzu\.com/i;
}

sub outputFilename {
    return "kudzuResults.txt";
}

sub pageName {
    return "Kudzu";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameElem = $tree->look_down('_tag', 'h1', 'class', 'profileTitle');
    if ($nameElem) {
	my $name = $nameElem->as_text();
	my $name = $nameElem->as_text();
	$name =~ s/\s+MD$//i; # Take of trailing MD
	    
	# TODO: Move this to ParserCommon - it exists here and in YellowPages
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

    print STDERR "Bad Kudzu page $path\n";
    return "--", "--";
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = "--";

    my $ratingOuterElem = $tree->look_down('class', 'profileRateReview');
    if ($ratingOuterElem) {
	my $ratingElem = $ratingOuterElem->look_down('itemprop', 'average');
	if ($ratingElem) {
	    # Hopefully we are lucky and tree parser didn't take out this meta tag
	    $rating = $ratingElem->attr('content');
	} else {
	    my $ratingInnerElem = $ratingOuterElem->look_down('itemprop', 'rating');
	    if ($ratingInnerElem) {
		# something like "rating-newstar rating-newstar-35" (for 3.5)
		my $ratingClass = $ratingInnerElem->attr('class');
		if ($ratingClass =~ m/(\d+)$/) {
		    my $val = $1;
		    if (length($val) > 1) {
			$rating = substr($val, 0, 1) . "." . substr($val, 1);
		    } else {
			$rating = $val;
		    }
		}
	    }
	}	

	my $ratingCountElem = $tree->look_down('itemprop', 'count');
	$ratingCount = $ratingCountElem->as_text() if $ratingCountElem;
    }
    return $rating, $ratingCount;
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};    my $doctorId = shift;
    my $path = shift;

    my $tree = HTML::Tree->new_from_file($path);

    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my ($rating, $ratingCount) = $self->getRatingFromTree($tree, $path);

    my ($googlePage, $googleResult) = $self->getGooglePage($path);

    my ($city, $state, $zip);
    my $addrLocal = $tree->look_down('itemprop', 'addressLocality');
    if ($addrLocal) {
	$city = $addrLocal->as_text();
    }
    my $addrRegion = $tree->look_down('itemprop', 'addressRegion');
    if ($addrRegion) {
	$state = $addrRegion->as_text();
    }
    my $addrZip = $tree->look_down('itemprop', 'postalCode');
    if ($addrZip) {
	$zip = $addrZip->as_text();
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
