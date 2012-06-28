package VimoParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for Vimo. Gets: doctorId, First Name, Last Name, Gender, City, Zip code, State, Overall rating, Knowledge and Skill, Availability, Punctuality, Personal skills, Office staff

# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "First Name", "Last Name", "Gender", "City", "State", "Zip code", "Overall rating", "Knowledge and Skill", "Availability", "Punctuality", "Personal skills", "Office staff"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/vimo\.com/i;
}

sub outputFilename {
    return "vimoResults.txt";
}

sub pageName {
    return "Vimo";
}


sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('_tag', 'h1', 'class', 'bdrnone');

    if (!$nameElem) {
	print STDERR "Bad Vimo page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    # Take off "(MD)"
    $fullName =~ s/\(MD\)//i;
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    die "Should not call getRatingFromTree on VimoParser."
}

sub getDataFields {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;
    my $tree = HTML::Tree->new_from_file($path);
 
    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my $personalDetailsElem = $tree->look_down('_tag', 'dl', 'style', 'margin-top: 0;');
    my $gender = "";
    my $city = "";
    my $state = "";
    my $zip = "";
    if ($personalDetailsElem) {
	# These come in pairs of dt -> dd. We're just going to hardcode the
	# location of the ones we're interested until we find out that they sometimes are missing.
	my @dds = $personalDetailsElem->look_down('_tag', 'dd');
	$gender = $dds[1]->as_text() if $dds[1];

	# There can be more than one address, but this will take the first by default
	my $addressElem = $tree->look_down('_tag', 'table', 'width', '200');
	my $cityStateElem = $tree->look_down('_tag', 'div', 'style', 'text-align: left; width: 150px;');
	if ($cityStateElem) {
	    if ($cityStateElem->as_HTML() =~ m/([^>]*),\s+([A-Z]+)\s+(\d+-?\d*)/i) {
		$city = $1;
		$state = $2;
		$zip = $3;
	    } else {
		print STDERR "Vimo parser couldn't parse city state " . $cityStateElem->as_HTML() . " in path $path\n";
	    }
	}
    }

    my $overallRating = "--"; 
    my $knowledgeAndSkill = "--";
    my $availability = "--";
    my $punctuality = "--";
    my $personalSkills = "--";
    my $officeStaff = "--";
    my $ratingsLinkOuterElem = $tree->look_down('class', 'review');
    my $ratingsLinkElem;
    $ratingsLinkElem = $ratingsLinkOuterElem->look_down('_tag', 'a') if $ratingsLinkOuterElem;
    if ($ratingsLinkElem) {
	# Need to get a file if it doesn't exist.
	my $outputPath = $path;
	$outputPath =~ m/([^\/]*)$/;
	my $filePart = $1;
	$outputPath =~ s/[^\/]*$//;
	$outputPath .= "vimo";
	mkdir $outputPath unless -d $outputPath;
	$outputPath .= "/" . $filePart;

	my $content = get("http://www.vimo.com" . $ratingsLinkElem->attr('href'));

	open(FO, ">$outputPath") or die "Could not open $outputPath $!";
	print FO $content;
	close(FO);

	my $ratingTree = HTML::Tree->new_from_file($outputPath);
	
	my $ratingTableElem = $ratingTree->look_down('_tag', 'table', 'width', '300');
	if ($ratingTableElem) {
	    my @rows = $ratingTableElem->look_down('_tag', 'tr');
	    foreach my $row (@rows) {
		my @cells = $row->look_down('_tag', 'td');
		my $name = $cells[0]->as_text();
		my $ratingElem = $cells[1]->look_down('_tag', 'span');
		my $rating = "--";
		if ($ratingElem && $ratingElem->attr('title') =~ m/Rating: (\d+\.?\d*)/i) {
		    $rating = $1;
		}
		if ($name eq "Overall Review Score:") {
		    $overallRating = $rating;
		} elsif ($name eq "Knowledge and Skill") {
		    $knowledgeAndSkill = $rating;
		} elsif ($name eq "Availability") {
		    $availability = $rating;
		} elsif ($name eq "Punctuality") {
		    $punctuality = $rating;
		} elsif ($name eq "Personal skills") {
		    $personalSkills = $rating;
		} elsif ($name eq "Office Staff") {
		    $officeStaff = $rating;
		} else {
		    print STDERR "Vimo parser couldn't handle rating for $name\n";
		}
	    }
	} else {
	    print STDERR "Vimo: No ratings table found in file $outputPath\n";
	}
    }

    my %output;
    $output{"ID"} = $doctorId;
    $output{"Last Name"} = $lastName;
    $output{"First Name"} = $firstName;
    $output{"City"} = $city;
    $output{"State"} = $state;
    $output{"Zip code"} = $zip;
    $output{"Gender"} = $gender;
    $output{"Overall rating"} = $overallRating;
    $output{"Knowledge and Skill"} = $knowledgeAndSkill;
    $output{"Availability"} = $availability;
    $output{"Punctuality"} = $punctuality;
    $output{"Personal skills"} = $personalSkills;
    $output{"Office staff"} = $officeStaff;
    return %output;
}

1;
