package HealthGradesParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parser class for healthgrades.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{RESULTDIR} = shift;
    $self->{INITED} = 0;
    bless($self, $class);
    return $self;
}

sub init() {
    # Initializes this parser and sub-parsers
    my $self = shift;
    open($self->{OUTHANDLE}, "> $self->{RESULTDIR}/healthGradesResults.txt") or die "Could not open health grades results $!";
    my $handle = $self->{OUTHANDLE};
    print $handle "ID\tReview-LastName\tReview-Firstname\tRating\n";
    $self->{INITED} = 1;
}

sub teardown() {
    my $self = shift;
    close($self->{OUTHANDLE});
    $self->{INITED} = 0;
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};

    my $doctorId = shift;
    my $path = shift;

    my $tree = HTML::Tree->new_from_file($path);

    my $nameSection = $tree->look_down('id', 'physician-name-h1');

    if (!$nameSection) {
	my $handle = $self->{OUTHANDLE};
	print $handle "$doctorId\t--\t--\t--\n";
	print STDERR "Bad health grades page $path\n";
	return;
    }

    my $fullName = $nameSection->as_text();
    $fullName =~ s/^\s*Dr\.\s*//;
    my ($firstName, $lastName) = ParserCommon::parseName($fullName);

    my $ratingSection = $tree->look_down(sub {
	$_[0]->tag() eq 'div' &&
	$_[0]->attr('class') eq 'ratingSection' &&
	$_[0]->as_text() =~ m/Overall/
					 });
    my $rating = "--";
    if ($ratingSection) {
	my @starElements = $ratingSection->look_down('_tag', 'li');
	$rating = 0.0;
	foreach my $starElem (@starElements) {
	    if ($starElem->attr('class') eq "starSmallYellowFull") {
		$rating++;
	    } elsif ($starElem->attr('class') eq "starSmallYellowHalf") {
		$rating += 0.5;
	    } elsif ($starElem->attr('class') ne "starSmallWhite") {
		die "Got unexpected star when parsing Health Grades for doctor $doctorId:" . $starElem->attr('class');
	    }
	}
    }

    my $handle = $self->{OUTHANDLE};
    print $handle "$doctorId\t$lastName\t$firstName\t$rating\n";
}
1;
