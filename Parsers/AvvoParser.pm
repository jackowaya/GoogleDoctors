package AvvoParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for Avvo. Gets: doctorId, First Name, Last Name, Gender, City, Zip code, State, Overall Avvo Rating (1-10), Experience (1-10), Industry recognition (1-10), Professional conduct (1-10), Average patient rating based on reviews (1-5), Number of Reviews
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "First Name", "Last Name", "Gender", "City", "State", "Zip code", "Overall Avvo Rating (1-10)", "Experience (1-10)", "Industry recognition (1-10)", "Professional conduct (1-10)", "Average patient rating based on reviews (1-5)", "Number of Reviews"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/avvo\.com/i;
}

sub outputFilename {
    return "avvoResults.txt";
}

sub pageName {
    return "Avvo";
}


sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('class', 'profile_title');

    if (!$nameElem) {
	print STDERR "Bad Avvo page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    # Take off "Dr. "
    $fullName =~ s/^\s*Dr\.\s+//;
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    die "Should not call getRatingFromTree on AvvoParser."
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;
    my $tree = HTML::Tree->new_from_file($path);
 
    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my $gender = "";
    my $genderElem = $tree->look_down('id', 'gender_detail');
    $gender = $genderElem->as_text() if $genderElem;

    my ($googlePage, $googleResult) = $self->getGooglePage($path);

    my $city = "";
    my $state = "";
    my $zip = "";
    # There can be more than one address_city_state, but this will take the first by default
    my $cityStateElem = $tree->look_down('class', 'address_city_state');
    if ($cityStateElem) {
	if ($cityStateElem->as_text() =~ m/(.*),\s+([A-Z]+)\s+(\d+-?\d*)/i) {
	    $city = $1;
	    $state = $2;
	    $zip = $3;
	} elsif ($cityStateElem->as_text() =~ m/(.*),\s+([A-Z]+)/i) {
	    $city = $1;
	    $state = $2;
	} else {
	    print STDERR "Avvo parser couldn't parse city state " . $cityStateElem->as_text() . " in path $path\n";
	}
    }

    my $avvoRating = "--";
    my $experience = "--";
    my $industryRecognition = "--";
    my $professionalConduct = "--";
    my $averagePatientRating = "--";
    my $numberOfReviews = 0;
    my $ratingsElem = $tree->look_down('id', 'ratings_overview');
    if ($ratingsElem) {
	my $ratingOuterElem = $ratingsElem->look_down('id', 'avvo_rating');
	if ($ratingOuterElem) {
	    my $ratingElem = $ratingOuterElem->look_down('class', 'value');
	    $avvoRating = $ratingElem->as_text() if $ratingElem;
	    print STDERR "Bad Avvo path $path\n" unless $ratingElem;
	}

	my $subRatingsElem = $tree->look_down('id', 'sub_rating');
	if ($subRatingsElem) {
	    my @rows = $subRatingsElem->look_down('_tag', 'tr');
	    if (@rows) {
		foreach my $row (@rows) {
		    my @cells = $row->look_down('_tag', 'td');
		    my $name = $cells[0]->as_text();
		    my $value = $cells[1]->look_down('_tag', 'img')->attr('alt');
		    $value =~ s/ Star Rating//i;
		    if ($name eq "Experience") {
			$experience = $value;
		    } elsif ($name eq "Industry Recognition") {
			$industryRecognition = $value;
		    } elsif ($name eq "Professional Conduct") {
			$professionalConduct = $value;
		    } else {
			print STDERR "Avvo parser doesn't know how to assign $name\n";
		    }
		}
	    }
	} else { print STDERR "No subratings!\n"; }
	
	my $clientRatingsElem = $tree->look_down('class', 'client_review_star_rating');
	if ($clientRatingsElem) {
	    my $countOuterElem = $clientRatingsElem->look_down('class', 'count');
	    if ($countOuterElem) {
		my $countElem = $countOuterElem->look_down('_tag', 'strong');
		$numberOfReviews = $countElem->as_text() if $countElem;
	    }
	    
	    my $ratingOuterElem = $clientRatingsElem->look_down('class', 'star_rating');
	    if ($ratingOuterElem) {
		my $ratingElem = $ratingOuterElem->look_down('_tag', 'img');
		if ($ratingElem) {
		    $averagePatientRating = $ratingElem->attr('alt');
		    $averagePatientRating =~ s/ star rating//i;
		}
	    }
	}
    }

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Google-Page"} = $googlePage;
    $output{"Google-Result"} = $googleResult;
    $output{"Last Name"} = $lastName;
    $output{"First Name"} = $firstName;
    $output{"City"} = $city;
    $output{"State"} = $state;
    $output{"Zip code"} = $zip;
    $output{"Gender"} = $gender;
    $output{"Overall Avvo Rating (1-10)"} = $avvoRating;
    $output{"Experience (1-10)"} = $experience;
    $output{"Industry recognition (1-10)"} = $industryRecognition;
    $output{"Professional conduct (1-10)"} = $professionalConduct;
    $output{"Average patient rating based on reviews (1-5)"} = $averagePatientRating;
    $output{"Number of Reviews"} = $numberOfReviews;
    return %output;
}

1;
