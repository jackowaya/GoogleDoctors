package DrScoreParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for drscore.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;
use LWP::Simple;

sub new {
    my $class = shift;
    my $resultDir = shift;
    my $self = $class->SUPER::new($resultDir);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/drscore\.com/i;
}

sub outputFilename {
    return "drScoreResults.txt";
}

sub pageName {
    return "Dr Score";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;
    my $nameElem = $tree->look_down('class', 'naming');

    if (!$nameElem) {
	print STDERR "Bad Doctor Score page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();
    $fullName =~ s/^Dr\.\s*//i;
    return ParserCommon::parseName($fullName);
}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $rating = "--";
    my $ratingCount = 0;
    my $ratingSection = $tree->look_down('id', 'profileleft');
    if (!$ratingSection) {
	return $rating, $ratingCount;
    }
    
    my $ratingLink = $tree->look_down(sub {
	$_[0]->tag() eq 'a' &&
	    $_[0]->as_text() =~ m/View ratings/i });
    if (!$ratingLink) {
	return $rating, $ratingCount;
    }

    # Need to get a file if it doesn't exist.
    my $outputPath = $path;
    $outputPath =~ m/([^\/]*)$/;
    my $filePart = $1;
    $outputPath =~ s/[^\/]*$//;
    $outputPath .= "drscore";
    mkdir $outputPath unless -d $outputPath;
    $outputPath .= "/" . $filePart;

    my $content = get($ratingLink->attr('href'));

    open(FO, ">$outputPath") or die "Could not open $outputPath $!";
    print FO $content;
    close(FO);

    my $ratingTree = HTML::Tree->new_from_file($outputPath);
    my $ratingElem = $ratingTree->look_down('class', 'profile_desc');
    if (!$ratingElem) {
	die "After path $path, downloaded $outputPath but couldn't find rating";
    }
    my $ratingText = $ratingElem->as_text();
    $ratingText =~ m/overall rating is (\d+\.?\d*).*a total of (\d+)/i;
    $rating = $1;
    $ratingCount = $2;
    
    return $rating, $ratingCount;
}

1;
