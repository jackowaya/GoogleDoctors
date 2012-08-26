package UCompareParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for ucomparehealthcare.com. Gets: doctorID, Review-Lastname, City, State, Zip-Code, Review-Firstname, rating, Recommendation, Waiting-Time, Ease-of-Appointment, Wait-Time-Length, Staff-Professional-Friendly, Problem-Accurately-Diagnosed, Doctor-Spent-Enough-Time, Appropriate-Follow-Up
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "City", "State", "Review-Rating", "Ease-of-Appointment", "Wait-Time-Length", "Staff-Professional-Friendly", "Problem-Accurately-Diagnosed", "Doctor-Spent-Enough-Time", "Appropriate-Follow-Up"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/ucomparehealthcare\.com/i;
}

sub outputFilename {
    return "ucompareHealthcareResults.txt";
}

sub pageName {
    return "UCompare Healthcare"
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameSection = $tree->look_down('class', 'item vcard');
    my $name = "";
    if ($nameSection) {
	my $nameElem = $nameSection->look_down('class', 'fn');
	$name = $nameElem->as_text();
    } else {
	$nameSection = $tree->look_down('class', 'vcard');
	if ($nameSection) {
	    my $nameElem = $nameSection->look_down('_tag', 'h1');
	    $name = $nameElem->as_text();
	}
    }

    $name =~ s/^\s*Dr\.\s*//i;

    if ($name eq "") {
	print STDERR "Bad UCompare path $path\n";
	return "--", "--";
    }
    return ParserCommon::parseName($name);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = 0;
    my $reviewSection = $tree->look_down('class', 'ind-reviews-summary ind-reviews-none');
    if ($reviewSection) {
	if ($reviewSection->as_text() =~ m/an average rating of (\d+\.?\d*).*based on (\d+)/i) {
	    $rating = $1;
	    $ratingCount = $2;
	} else {
	    print STDERR "UCompare could not handle review section " . $reviewSection->as_text() . "\n";
	} 
    } else {
	$reviewSection = $tree->look_down('class', 'clear rating-average');
	if ($reviewSection) {
	    my $reviewElem = $reviewSection->look_down('_tag', 'a');
	    if ($reviewElem && $reviewElem->attr('title') =~ m/(\d+\.?\d*).*\((\d+) review/i) {
		$rating = $1;
		$ratingCount = $2;
	    } else {
		print STDERR "UCompare could not deal with review section " . $reviewSection->as_HTML() . "\n";
	    }
	} else {
	    print STDERR "UCompare could not get rating from path $path\n";
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

    my ($city, $state);
    $city = $state = "--";
    my $vcardSection = $tree->look_down('class', 'item vcard');
    if ($vcardSection) {
	my $cityElem = $vcardSection->look_down('class', 'locality');
	$city = $cityElem->as_text() if $cityElem;

	my $stateElem = $vcardSection->look_down('class', 'region');
	$state = $stateElem->as_text() if $stateElem;
    }

    my ($easeOfAppointment, $waitTimeLength, $staffProfessionalFriendly, $problemAccuratelyDiagnosed, $doctorSpentEnoughTime, $appropriateFollowUp);
    $easeOfAppointment = $waitTimeLength = $staffProfessionalFriendly = $problemAccuratelyDiagnosed = $doctorSpentEnoughTime = $appropriateFollowUp = "";
    my $ratingsOuterElem = $tree->look_down('class', 'reviews-breakdown');
    if ($ratingsOuterElem) {
	my @lis = $ratingsOuterElem->look_down('_tag', 'li');
	foreach my $li (@lis) {
	    my $spanElem = $li->look_down('_tag', 'span');
	    my $score = "--";
	    if ($spanElem && $spanElem->attr('class') =~ m/rstars(\d+-?\d*)/i) {
		$score = $1;
		$score =~ s/-/\./;
	    }
	    if ($li->as_text() =~ m/easy to get an appointment/i) {
		$easeOfAppointment = $score;
	    } elsif ($li->as_text() =~ m/wait time was short/i) {
		$waitTimeLength = $score;
	    } elsif ($li->as_text() =~ m/staff was professional/i) {
		$staffProfessionalFriendly = $score;
	    } elsif ($li->as_text() =~ m/problem was accurately/i) {
		$problemAccuratelyDiagnosed = $score;
	    } elsif ($li->as_text() =~ m/doctor spent enough time/i) {
		$doctorSpentEnoughTime = $score;
	    } elsif ($li->as_text() =~ m/appropriate follow up/i) {
		$appropriateFollowUp = $score;
	    }
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
    $output{"Ease-of-Appointment"} = $easeOfAppointment;
    $output{"Wait-Time-Length"} = $waitTimeLength;
    $output{"Staff-Professional-Friendly"} = $staffProfessionalFriendly;
    $output{"Problem-Accurately-Diagnosed"} = $problemAccuratelyDiagnosed;
    $output{"Doctor-Spent-Enough-Time"} = $doctorSpentEnoughTime;
    $output{"Appropriate-Follow-Up"} = $appropriateFollowUp;
    return %output;
}

1;
