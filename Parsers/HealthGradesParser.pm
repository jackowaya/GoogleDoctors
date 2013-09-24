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
    #my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "Gender", "City", "State", "Zip-Code", "Recommendation", "Number-Patient-Surveys", "Trust", "Communicates", "Listens", "Time-Spent", "Scheduling-Appts", "Office-Environment", "Office-Friendliness", "Wait-Time"];
    my $fieldsRef = ["ID", "Google-Page", "Google-Result", "Review-LastName", "Review-FirstName", "Review-Rating", "Number-of-Ratings", "Gender", "City", "State", "Zip-Code", "Recommendation", "Trust", "Communicates", "Listens", "Time-Spent", "Scheduling-Appts", "Office-Environment", "Office-Friendliness", "Wait-Time"];
    my $self = $class->SUPER::new(shift, $fieldsRef);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/healthgrades\.com\/physician/i;
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

    my $rating = "--";
    my $ratingCount = 0;
    
    my $ratingElem = $tree->look_down('class', 'summarySpecialty');
    if($ratingElem){
	my $ratingElemInner = $tree->look_down('class','fill-to-expand');
	if ($ratingElemInner){
	    $rating = $ratingElemInner->as_text();
	}
	my $ratingElemInner = $tree->look_down('class',"");
	if ($ratingElemInner){
	    $ratingCount = $ratingElemInner->as_text();
	}
    }
    
    
    # if ($ratingSection) {
	# # my $ratingElem = $ratingSection->look_down('class', 'value');
	# # $rating = $ratingElem->as_text();

	# # my $countElem = $ratingSection->look_down('class', 'votes');
	# # $ratingCount = $countElem->as_text();
    # } else {
	# # Another type of page.
	# $ratingSection = $tree->look_down('class', 'qualityBarTipsLeftColumn');
	# if ($ratingSection) {
	    # my $ratingElem = $ratingSection->look_down('_tag', 'strong');
	    # $rating = $ratingElem->as_text() if $ratingElem;

	    # my $countElem = $ratingSection->look_down('style', 'font-size:11px;');
	    # if ($countElem) {
		# my $count = $countElem->as_text();
		# if ($count =~ m/Based on (\d+) HealthGrades/i) {
		    # $ratingCount = $1;
		# }
	    # }
	# }
    # }

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

    my $surveyLink = $tree->look_down('data-hgoname', 'quality-survey-results-has-surveys');
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

    my $genderOuterElem = $tree->look_down('class', 'category');
    if ($genderOuterElem) {
	my $genderInnerElem = $genderOuterElem->look_up('_tag', 'h2');
	if ($genderInnerElem && $genderInnerElem->as_text() =~ m/((Fe)?male)/i) {
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

    # my $numSurveys = "--";
    # my $surveyCountElem = $tree->look_down('class', 'qualitySurveyHeaderRightColumn');
    # if ($surveyCountElem && $surveyCountElem->as_text() =~ m/based on (\d+) completed surveys/i) {
	# $numSurveys = $1;
    # } elsif ($surveyCountElem && $surveyCountElem->as_text() =~ m/based on (\d+) patient satisfaction surveys/i) {
	# $numSurveys = $1;
    # }

    my ($recommendation, $trust, $communicates, $listens, $timeSpent, $scheduling, $officeEnv, $officeFriendly, $waitTime);
    $recommendation = $trust = $communicates = $listens = $timeSpent = $scheduling = $officeEnv = $officeFriendly = $waitTime = "--";
    
    my $recElem = $tree->look_down('class','rating');
    if ($recElem){$recommendation = $recElem->as_text;}
    my @rows = $tree->look_down('class',"surveyLabelCol surveyRow");
    if(@rows){
	    foreach my $row (@rows){
		    my $label = $row->as_text;
		    my $scoreElem;
		    my $rowElem = $row->look_up('_tag','tr');
		    if ($label =~ m/Wait Time/i) {
			$scoreElem = $rowElem->look_down('class','calloutLabel');
			if($scoreElem) {$waitTime = $scoreElem->as_text;}
		    } else{
			$scoreElem = $rowElem->look_down('class','fill-to-expand');
			if ($scoreElem){
				my $score = $scoreElem->as_text;
				if ($label =~ m/Scheduling/i) {
				    $scheduling = $score;
				} elsif ($label =~ m/Office Environment/i) {
				    $officeEnv = $score;
				} elsif ($label =~ m/Staff Friendliness/i) {
				    $officeFriendly = $score;
				} elsif ($label =~ m/Level of Trust/i) {
				    $trust = $score;
				} elsif ($label =~ m/Explains Medical Condition/i) {
				    $communicates = $score;
				} elsif ($label =~ m/Listens and Answers/i) {
				    $listens = $score;
				} elsif ($label =~ m/Appropriate Amount of Time/i) {
				    $timeSpent = $score;
				}
			}
		    }	
	    }
    }
    # my $surveyOuterElem = $tree->look_down('class', 'surveyLayoutInner');
    # if ($surveyOuterElem) {
	# my @rows = $surveyOuterElem->look_down('_tag', 'tr');
	# if (@rows) {
	    # foreach my $row (@rows) {
		# my @cells = $row->look_down('_tag', 'td');
		# if (@cells && scalar(@cells) == 3) {

		    # my $labelElem = $cells[0]->look_down('_tag', 'strong');
		    # my $label = "";
		    # $label = $labelElem->as_text() if $labelElem;
		    # my $score = "";
		    # my $scoreElem = $cells[2]->look_down(sub {
			# $_[0]->tag() eq "span" && $_[0]->attr('class') =~ m/ratingBar/i
							 # });
		    # if ($scoreElem && $scoreElem->attr('class') =~ m/fill-to-(\d+)/i) {
			# $score = $1;
		    # }
		    
		    # if ($label =~ m/Scheduling Appointment/i) {
			# $scheduling = $score;
		    # } elsif ($label =~ m/Office Environment/i) {
			# $officeEnv = $score;
		    # } elsif ($label =~ m/Office Friendliness/i) {
			# $officeFriendly = $score;
		    # } elsif ($label =~ m/Wait Time/i) {
			# my $waitElem = $cells[2]->look_down('_tag', 'strong');
			# $waitTime = $waitElem->as_text() if $waitElem;
		    # } elsif ($label =~ m/Level of Trust/i) {
			# $trust = $score;
		    # } elsif ($label =~ m/Helps Patients Understand/i) {
			# $communicates = $score;
		    # } elsif ($label =~ m/Listens and Answers/i) {
			# $listens = $score;
		    # } elsif ($label =~ m/Time Spent/i) {
			# $timeSpent = $score;
		    # } elsif ($label =~ m/Recommend/i) {
			# $recommendation = $score;
		    # }
		# }
	    # }
	# }
    # }

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
    $output{"Recommendation"} = $recommendation;
    # $output{"Number-Patient-Surveys"} = $numSurveys;
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
