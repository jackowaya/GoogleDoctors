package ThirdAgeParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for third age. Gets: doctorID, Review-Lastname, Review-Firstname, gender, city, state, zip code, rating, number-of-ratings (always "--")
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "Gender", "City", "State", "Zip-Code", "Review-Rating"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/thirdage\.com/i;
}

sub outputFilename {
    return "thirdAgeResults.txt";
}

sub pageName {
    return "Third Age";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $outerElem = $tree->look_down('class', 'doctor_box');

    if (!$outerElem) {
	print STDERR "Bad EverydayHealth page $path\n";
	return "--", "--";
    }
	
	my $nameElem = $outerElem->look_down('_tag', 'h1');
	
	if (!$nameElem) {
	print STDERR "Bad EverydayHealth page 2 $path\n";
	return "--", "--";
    }
	
    return ParserCommon::parseName($nameElem->as_text());
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $ratingBlock = $tree->look_down('class', 'review_rating');
    my $rating = "--";
    my $ratingCount = "--";
    if ($ratingBlock) {
	my @starsOn = $ratingBlock->look_down(sub {
	$_[0]->attr('class') =~ m/star-rating-on/i
	});
	$rating = scalar(@starsOn);
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

	my ($gender, $city, $state, $zip);
	$gender = $city = $state = $zip = "--";
	my $detailsBlock = $tree->look_down('class', 'additional_box');
	if ($detailsBlock) {
		my @titles = $detailsBlock->look_down('class', 'left_additional');
		my @values = $detailsBlock->look_down('class', 'right_additional');
		for (my $i = 0; $i < scalar(@titles) && $i < scalar(@values); $i++) {
			if ($titles[$i]->as_text() =~ m/Gender/i) {
				$gender = $values[$i]->as_text();
			} elsif ($titles[$i]->as_text() =~ m/Address/) {
				if ($values[$i]->as_HTML() =~ m/([^>]+), (\w+) (\d+)/) {
					$city = $1;
					$state = $2;
					$zip = $3;
				} else {
					print STDERR "Could not handle address " . $values[$i]->as_HTML();
				}
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
	$output{"Gender"} = $gender;
	$output{"City"} = $city;
	$output{"State"} = $state;
	$output{"Zip-Code"} = $zip;
    return %output;
}


1;
