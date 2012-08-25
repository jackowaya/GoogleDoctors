package EverydayHealthParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for everyday health. Gets: doctorID, Review-Lastname, Review-Firstname, city, state, zip code, rating, number-of-ratings, Likely to Recommend (1-5), Knowledge and Skill (1-5), Responsive and Accessible  (1-5), Bedside Manner (1-5), Waiting Time 
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "City", "State", "Zip-Code", "Review-Rating", "Number-of-Ratings", "Likely to Recommend (1-5)", "Knowledge and Skill (1-5)", "Responsive and Accessible (1-5)", "Bedside Manner (1-5)"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/everydayhealth\.com/i;
}

sub outputFilename {
    return "everydayHealthResults.txt";
}

sub pageName {
    return "Everyday Health";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameElem = $tree->look_down('class', 'page-header');

    if (!$nameElem) {
	print STDERR "Bad EverydayHealth page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    # Replace &nbsp (character 160 octal 240) with space (32 octal 40)
    $fullName =~ s/\240/\40/g; 
    $fullName =~ s/^\s*Dr\.\s*//i;
    return ParserCommon::parseName($fullName);

}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $ratingBlock = $tree->look_down('class', 'provider-rating');
    my $rating = "--";
    my $ratingCount = 0;
    if ($ratingBlock) {
	my $ratingElem = $ratingBlock->look_down('style', 'margin-left:130px;');
	$rating = $ratingElem->as_text() if $ratingElem;
    }
	
	my $countElem = $tree->look_down('class', 'number-review');
	if ($countElem && $countElem->as_text() =~ m/Based on (\d+) Reviews/i) {
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

    my ($city, $state, $zip);
    $city = $state = $zip = "";
    my $locationBlock = $tree->look_down('class', 'location');
    if ($locationBlock) {
	my @parts = split(/\<br \/\>/i, $locationBlock->as_HTML());
	($city, $state, $zip) = ParserCommon::parseCityStateZip($parts[1]);
    }

    my ($likely, $knowledge, $responsive, $bedside);
    $likely = $knowledge = $responsive = $bedside = "--";
    my $ratingsBlock = $tree->look_down('class', 'columns reviews');
    if ($ratingsBlock) {
	my @ratingsPieces = $ratingsBlock->look_down(sub {
	    $_[0]->attr('class') =~ m/subcol\d/i
						     });
	if (@ratingsPieces) {
	    for my $ratingPiece (@ratingsPieces) {
		my $avgElem = $ratingPiece->look_down('_tag', 'span');
		my $subHeaderElem = $ratingPiece->look_down('class', 'sub-header');
		if ($avgElem && $subHeaderElem) {
		    my $subtext = $subHeaderElem->as_text();
		    if ($subtext =~ m/Likely to Recommend/i) {
			$likely = $avgElem->as_text();
		    } elsif ($subtext =~ m/Knowledge and Skill/i) {
			$knowledge = $avgElem->as_text();
		    } elsif ($subtext =~ m/Responsive and Accessible/i) {
			$responsive = $avgElem->as_text();
		    } elsif ($subtext =~ m/Bedside Manner/i) {
			$bedside = $avgElem->as_text();
		    } else {
			print STDERR "Everyday Health doesn't support $subtext\n";
		    }
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
    $output{"City"} = $city;
    $output{"State"} = $state;
    $output{"Zip-Code"} = $zip;
    $output{"Likely to Recommend (1-5)"} = $likely;
    $output{"Knowledge and Skill (1-5)"} = $knowledge;
    $output{"Responsive and Accessible (1-5)"} = $responsive;
    $output{"Bedside Manner (1-5)"} = $bedside;
    return %output;
}


1;
