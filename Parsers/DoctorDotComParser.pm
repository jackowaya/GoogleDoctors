package DoctorDotComParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for doctor.com. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip, DocPoints, Patient-DocPoints
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "Gender", "DocPoints", "Patient-DocPoints"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/doctor\.com/i;
}

sub outputFilename {
    return "doctorDotComResults.txt";
}

sub pageName {
    return "Doctor.com";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameElem = $tree->look_down('_tag', 'h1', 'itemprop', 'name');
    if ($nameElem) {
	my $name = $nameElem->as_text();
	# Remove Dr.
	$name =~ s/^Dr\.\s*//i;
	return ParserCommon::parseName($name);
    }

    print STDERR "Bad Doctor.com page $path\n";
    return "--", "--";
}

sub getRatingFromTree {
    die "DoctorDotCom Uses two docpoints calculations instead of getRating";
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;

    my $tree = HTML::Tree->new_from_file($path);

    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my ($googlePage, $googleResult) = $self->getGooglePage($path);

    my ($gender, $docPoints, $patientDocPoints);
    $gender = $docPoints = $patientDocPoints = "--";

    my $docInfoOuterElem = $tree->look_down('class', 'provDtxt');
    if ($docInfoOuterElem) {
	my @ps = $docInfoOuterElem->look_down('_tag', 'p');
	if (@ps) {
	    foreach my $p (@ps) {
		if ($p->as_text() =~ m/Gender:\s*(\w+)/i) {
		    $gender = $1;
		}
	    }
	}
    }

    my $docPointsElem = $tree->look_down('class', 'clrR');
    $docPoints = $docPointsElem->as_text() if $docPointsElem;
    
    my $patientDocPointsElem = $tree->look_down('class', 'clrB');
    if ($patientDocPointsElem) {
	$patientDocPoints = $patientDocPointsElem->as_text();
	$patientDocPoints =~ s/\/80//; # take off "/80"
    }

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Google-Page"} = $googlePage;
    $output{"Google-Result"} = $googleResult;
    $output{"Review-LastName"} = $lastName;
    $output{"Review-FirstName"} = $firstName;
    $output{"Gender"} = $gender;
    $output{"DocPoints"} = $docPoints;
    $output{"Patient-DocPoints"} = $patientDocPoints;
    return %output;
}

1;
