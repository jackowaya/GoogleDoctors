package HealthGradesParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for healthgrades.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating, Number-of-ratings, Gender, City, Zip-Code, State, Recommendation, Number-Patient-Surveys, Trust, Communicates, Listens, Time-Spent, Scheduling-Appts, Office-Environment, Office-Friendliness, Wait-Time

# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "Gender", "City", "State", "Zip-Code", "Review-Rating", "Number-of-Ratings", "Recommendation", "Number-Patient-Surveys", "Trust", "Communicates", "Listens", "Time-Spent", "Scheduling-Appts", "Office-Environment", "Office-Friendliness", "Wait-Time"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/healthgrades\.com/i;
}

sub outputFilename {
    return "healthGradesResults.txt";
}

sub pageName {
    return "Health Grades";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameSection = $tree->look_down('id', 'physician-name-h1');

    if (!$nameSection) {
	# Try another type of page
	my $lastName = $tree->look_down('class', 'family-name');
	my $firstName = $tree->look_down('class', 'given-name');
	if ($firstName && $lastName) {
	    return $firstName->as_text(), $lastName->as_text();
	}
	print STDERR "Bad health grades page $path\n";
	return "--", "--";
    }

    my $fullName = $nameSection->as_text();
    $fullName =~ s/^\s*Dr\.\s*//;
    return ParserCommon::parseName($fullName);

}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;

    my $ratingSection = $tree->look_down('id', 'overallPatientRating');
    my $rating = "--";
    my $ratingCount = 0;

    # HealthGrades Redesigned their site in August 2013. Try this one first
    $ratingSection = $tree->look_down('_tag', 'div', 'class', "calloutContainer size-medium ");
    if ($ratingSection) {
	my $ratingElem = $ratingSection->look_down('_tag', 'a');
	$ratingElem = $ratingElem->look_down('_tag', 'span');
	$rating = $ratingElem->as_text() if $ratingElem;

	my $countElem = $ratingSection ->look_down('_tag', 'a', 'class', 'responsesLabel');
	$countElem = $countElem->look_down('_tag', 'span');
	$ratingCount = $countElem->as_text() if $countElem;

	return $rating, $ratingCount;
    }


    if ($ratingSection) {
	my $ratingElem = $ratingSection->look_down('class', 'value');
	$rating = $ratingElem->as_text();

	my $countElem = $ratingSection->look_down('class', 'votes');
	$ratingCount = $countElem->as_text();
    } else {
	# Another type of page.
	$ratingSection = $tree->look_down('class', 'qualityBarTipsLeftColumn');
	if ($ratingSection) {
	    my $ratingElem = $ratingSection->look_down('_tag', 'strong');
	    $rating = $ratingElem->as_text() if $ratingElem;

	    my $countElem = $ratingSection->look_down('style', 'font-size:11px;');
	    if ($countElem) {
		my $count = $countElem->as_text();
		if ($count =~ m/Based on (\d+) HealthGrades/i) {
		    $ratingCount = $1;
		}
	    }
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

    my $surveyLink = $tree->look_down('_tag', 'div', 'class', "calloutContainer size-medium ");
    if ($surveyLink) {
	$surveyLink = $surveyLink->look_down('_tag', 'a', 'class', "responsesLabel");
    }

    if ($surveyLink) {
	my $outputPath = $path;
	$outputPath =~ s/\/\//\//g;
	$outputPath =~ m/([^\/]*)$/;
	my $filePart = $1;
	$outputPath =~ s/[^\/]*$//;
	my $downloadedDir = $outputPath;
	$outputPath .= "HealthGrades";
	mkdir $outputPath unless -d $outputPath;
	$outputPath .= "/" . $filePart;

	my $url = "http://www.healthgrades.com/" . $surveyLink->attr('href');
	    
	my $content = get($url);
		
	print STDERR "Writing $url to $outputPath\n";
	    
	open(FO, ">$outputPath") or die "Could not open $outputPath $!";
	print FO $content;
	close(FO);

	return $self->getData($doctorId, $outputPath);
    } else {
    	$surveyLink = $tree->look_down('data-hgoname', 'quality-survey-results-has-surveys');
	if ($surveyLink) {
	    my $outputPath = $path;
	    $outputPath =~ s/\/\//\//g;
	    $outputPath =~ m/([^\/]*)$/;
	    my $filePart = $1;
	    $outputPath =~ s/[^\/]*$//;
	    my $downloadedDir = $outputPath;
	    $outputPath .= "HealthGrades";
	    mkdir $outputPath unless -d $outputPath;
	    $outputPath .= "/" . $filePart;

	    my $url = "http://www.healthgrades.com/" . $surveyLink->attr('href');
	    
	    my $content = get($url);

	    print STDERR "Writing $url to $outputPath\n";
	    
	    open(FO, ">$outputPath") or die "Could not open $outputPath $!";
	    print FO $content;
	    close(FO);

    	    return $self->getData($doctorId, $outputPath);
	} else {
	    return $self->getData($doctorId, $path);
	}
    }
}

sub getData {
    my $self = shift;
    my $doctorId = shift;
    my $path = shift;

    my $tree = HTML::Tree->new_from_file($path);

    my ($firstName, $lastName) = $self->getNameFromTree($tree, $path);

    my ($rating, $ratingCount) = $self->getRatingFromTree($tree, $path);

    my ($googlePage, $googleResult) = $self->getGooglePage($path);

    my ($city, $state, $zip, $gender);
    $city = $state = $zip = $gender = "--";

    my $genderOuterElem = $tree->look_down('_tag', 'div', 'class', "summaryInnerTable" );
    if ($genderOuterElem) {
	my $genderInnerElem = $genderOuterElem->look_down('_tag', 'h2');
	if ($genderInnerElem && $genderInnerElem->as_text() =~ m/((?:Fe)?male),/i) {
	    
	    $gender = $1;
	}
    }

    my $addressOuterElem = $tree->look_down('class', 'summaryLocationInner');
    if ($addressOuterElem) {
	my $cityElem = $addressOuterElem->look_down('class', 'locality');
	$city = $cityElem->as_text() if $cityElem;
	$city =~ s/,$//;

	my $stateElem = $addressOuterElem->look_down('class', 'region');
	$state = $stateElem->as_text() if $stateElem;

	my $zipElem = $addressOuterElem->look_down('class', 'postal-code');
	$zip = $zipElem->as_text() if $zipElem;
    }

    my $numSurveys = "--";
    my $surveyCountElem = $tree->look_down('class', 'qualitySurveyHeaderRightColumn');
    if ($surveyCountElem && $surveyCountElem->as_text() =~ m/based on (\d+) completed survey/i) {
	$numSurveys = $1;
    } elsif ($surveyCountElem && $surveyCountElem->as_text() =~ m/based on (\d+) patient satisfaction survey/i) {
	$numSurveys = $1;
    }
    if ($ratingCount == 0 && $numSurveys ne "--") {
	$ratingCount = $numSurveys;
    }

    my ($recommendation, $trust, $communicates, $listens, $timeSpent, $scheduling, $officeEnv, $officeFriendly, $waitTime);
    $recommendation = $trust = $communicates = $listens = $timeSpent = $scheduling = $officeEnv = $officeFriendly = $waitTime = "--";
    my $surveyOuterElem = $tree->look_down('_tag', 'table', 'class', 'surveyTable');
    if ($surveyOuterElem) {
	my @rows = $surveyOuterElem->look_down('_tag', 'tr');
	if (@rows) {
	    foreach my $row (@rows) {
		my @cells = $row->look_down('_tag', 'td');
		if (@cells && scalar(@cells) == 2) {

		    my $labelElem = $cells[0]->look_down('class', 'surveyLabelCol surveyRow');
		    my $label = "";
		    $label = $labelElem->as_text() if $labelElem;
	 	    my $score = "";
		    my $scoreElem = $cells[1]->look_down('_tag', 'span', 'class', 'callout');
		    if ($scoreElem) {
			$score = $scoreElem->as_text();
		    }
		    
		    if ($label =~ m/Scheduling/i) {
			$scheduling = $score;
		    } elsif ($label =~ m/Office Environment/i) {
			$officeEnv = $score;
		    } elsif ($label =~ m/Friendliness/i) {
			$officeFriendly = $score;
		    } elsif ($label =~ m/Wait Time/i) {
			my $waitElem = $cells[1]->look_down('_tag', 'span', 'class', 'callout');
			$waitTime = $waitElem->as_text() if $waitElem;
		    } elsif ($label =~ m/Level of Trust/i) {
			$trust = $score;
		    } elsif ($label =~ m/provider explains/i) {
			$communicates = $score;
		    } elsif ($label =~ m/Listens and Answers/i) {
			$listens = $score;
		    } elsif ($label =~ m/spends/i) {
			$timeSpent = $score;
		    } elsif ($label =~ m/Recommend/i) {
			$recommendation = $score;
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
    $output{"Gender"} = $gender;
    $output{"Recommendation"} = $rating;
    $output{"Number-Patient-Surveys"} = $ratingCount;
    $output{"Trust"} = $trust;
    $output{"Communicates"} = $communicates;
    $output{"Listens"} = $listens;
    $output{"Time-Spent"} = $timeSpent;
    $output{"Scheduling-Appts"} = $scheduling;
    $output{"Office-Environment"} = $officeEnv;
    $output{"Office-Friendliness"} = $officeFriendly;
    $output{"Wait-Time"} = $waitTime;
    return %output;
}


1;
