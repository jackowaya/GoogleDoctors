package VitalsParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parser class for vitals.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
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
    open($self->{OUTHANDLE}, "> $self->{RESULTDIR}/vitalsResults.txt") or die "could not open vitals results $self->{RESULTDIR}/vitalsResults.txt $!";
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

    my $reviewSection = $tree->look_down('id', 'review_section');
    if (!$reviewSection) {
	# There is another type of vitals page that doesn't have review_section.
	my $nameSection = $tree->look_down('class', 'vcard rate');
	if (!$nameSection) {
	    $self->writeFailure($doctorId, $path);
	    return;
	}
	my $nameElem = $nameSection->look_down('_tag', 'h1', 'class', 'fn txtOrangeL');
	my $fullName = $nameElem->as_text();
	
	my $overallRatingImg = $tree->look_down(sub {
	    $_[0]->tag() eq 'img' &&
		$_[0]->attr('src') =~ m/r_stars\d\.\d\.gif/i
						});
	if (!$overallRatingImg) {
	    $self->writeFailure($doctorId, $path);
	    return;
	}

	my ($firstName, $lastName) = ParserCommon::parseName($fullName);
	$overallRatingImg->attr('src') =~ m/r_stars(\d\.\d)\.gif/i;
	my $rating = $1;

	my $handle = $self->{OUTHANDLE};
	print $handle "$doctorId\t$lastName\t$firstName\t$rating\n";
	return;
    }
	
    my $nameSection = $reviewSection->look_down('_tag', 'h2');

    my $fullName = $nameSection->as_text();
    $fullName =~ s/\s+Doctor\s+Ratings\s*$//;
    my ($firstName, $lastName) = ParserCommon::parseName($fullName);

    my $ratingSection = $reviewSection->look_down('class', 'value');
    my $rating = $ratingSection->as_text();

    my $handle = $self->{OUTHANDLE};
    print $handle "$doctorId\t$lastName\t$firstName\t$rating\n";
}

sub writeFailure {
    my $self = shift;
    my $doctorId = shift;
    my $path = shift;

    my $handle = $self->{OUTHANDLE};
    print $handle "$doctorId\t--\t--\t--\n";
    print STDERR "Bad vitals page $path\n";
}
1;
