package RateMdsParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parser class for ratemds.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
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
    open($self->{OUTHANDLE}, "> $self->{RESULTDIR}/rateMdsResults.txt") or die "Could not open ratemds results $!";
    my $handle = $self->{OUTHANDLE};
    print $handle "ID\tReview-LastName\tReview-Firstname\tRating\n";
    $self->{INITED} = 1;
}

sub teardown() {
    my $self = shift;
    my $handle = $self->{OUTHANDLE};
    close($handle);
    $self->{INITED} = 0;
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $doctorId = shift;
    my $path = shift;
    
    my $tree = HTML::Tree->new_from_file($path);
    my $nameElem = $tree->look_down('class', 'fn');

    if (!$nameElem) {
        my $handle = $self->{OUTHANDLE};
	print $handle "$doctorId\t--\t--\t--\n";
	print STDERR "Bad RateMds page $path\n";
	return;
    }

    my $fullName = $nameElem->as_text();

    my ($firstName, $lastName) = ParserCommon::parseName($fullName);

    # The last one that matches is the one we want.
    my @ratingRows = $tree->look_down(sub {
         $_[0]->tag() eq 'tr' &&
         $_[0]->as_text() =~ m/Overall\s+Quality\*/
    });
    my $ratingRow = pop(@ratingRows);

    my $rating = "--";
    if ($ratingRow) {
	# May not have ratings yet.
	my @ratingRowCells = $ratingRow->look_down('_tag', 'td');
	$rating = $ratingRowCells[2]->as_text();
    }
    my $handle = $self->{OUTHANDLE};
    print $handle "$doctorId\t$lastName\t$firstName\t$rating\n";
}

1;
