package LifescriptParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for Lifescript. Gets: doctorId, First Name, Last Name, Gender, City, Zip code, State, Review Score, Number of reviews
# NOTE: Currently not doing zip code because we didn't have an example
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "First Name", "Last Name", "Gender", "City", "State", "Review Score", "Number of reviews"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/lifescript\.com/i;
}

sub outputFilename {
    return "lifescriptResults.txt";
}

sub pageName {
    return "Lifescript";
}


sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('id', 'content_0_UxDoctorInfo_lblDocName');

    if (!$nameElem) {
	print STDERR "Bad Lifescript page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $rating = "--";
    my $ratingCount = 0;
    my $ratingElem = $tree->look_down('itemprop','ratingValue');
    if ($ratingElem) {
		$rating=$ratingElem->attr('content');
	} else {
	    print STDERR "Lifescript couldn't parse rating element text " . $ratingElem->as_text() . "\n";
	}
    	

    my $countElem = $tree->look_down('id', 'content_0_UxDoctorInfo_ctl01_numOfRatings');
    $ratingCount = $countElem->as_text() if $countElem;	
    if ($ratingCount =~ m/(\d+)/) {
	$ratingCount = $1;
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

    my $gender = "";
    my $city = "";
    my $state = "";
    my $detailsElem = $tree->look_down('id', 'content_0_UxDoctorInfo_lblDoctorInfo');
    if ($detailsElem) {
	my @detailParts = split(/\<br \/\>/, $detailsElem->as_HTML());
	if (scalar(@detailParts) != 4) {
	    print STDERR "Could not parse lifescript details " . $detailsElem->as_HTML() . "\n";
	}
	if ($detailParts[1] =~ m/(.*)\s+,\s+(.*)/) {
	    $city = $1;
	    $state = $2;
	}
	if ($detailParts[2] =~ m/(F?e?male)/i) {
	    $gender = $1;
	}
    }

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Google-Page"} = $googlePage;
    $output{"Google-Result"} = $googleResult;
    $output{"Last Name"} = $lastName;
    $output{"First Name"} = $firstName;
    $output{"Review Score"} = $rating;
    $output{"Number of reviews"} = $ratingCount;
    $output{"City"} = $city;
    $output{"State"} = $state;
    $output{"Gender"} = $gender;
    return %output;
}

1;
