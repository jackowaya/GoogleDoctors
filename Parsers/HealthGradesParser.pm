package HealthGradesParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parser class for healthgrades.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my $self->{RESULTDIR} = shift;
    my $self->{INITED} = 0;
    bless($self, $class);
    return $self;
}

sub init() {
    # Initializes this parser and sub-parsers
    open(MYOUT, $self->{RESULTDIR} . "/healthGradesResults.txt", "w");
    $self->{OUTHANDLE} = MYOUT;
    print $self->{OUTHANDLE} "ID\tReview-LastName\tReview-Firstname\tRating\n";
    $self->{INITED} = 1;
}

sub teardown() {
    close($self->{OUTHANDLE});
    $self->{INITED} = 0;
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};

    my $doctorId = shift;
    my $path = shift;

    my $tree = HTML::Tree->new_from_file($path);

    my $nameSection = $tree->look_down('id', 'physician_name_h1');

    my $fullName = $nameSection->text();
    $fullName =~ s/^\s*Dr\.\s*//;
    my ($firstName, $lastName) = parseName($fullName);

    my $ratingSection = $tree->look_down(_tag, 'div', 'class', 'ratingSection', sub {
	$_->text() =~ m/Overall/;
					 });
    my @starElements = $ratingSection->look_down(_tag, 'li');
    my $rating = 0;
    foreach my $starElem (@starElements) {
	if ($starElem->attr('class') eq "starSmallYellowFull") {
	    $rating++;
	} elsif ($strElem->attr('class') ne "starSmallWhite") {
	    die "Got unexpected star when parsing Health Grades for doctor $doctorId: $strElem->attr('class')";
	}
    }

    print $self->{OUTHANDLE} "$doctorId\t$lastName\t$firstName\t$rating\n";
}
1;
