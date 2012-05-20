package RateMdsParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parser class for ratemds.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use ParserCommon;

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
    open(MYOUT, $self->{RESULTDIR} . "/rateMdsResults.txt", "w");
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
    my $nameElem = $tree->look_down(_tag, 'span', 'class', 'fn');
    
    my $fullName = $nameElem->text();

    my ($firstName, $lastName) = parseName($fullName);

    my $ratingRow = $tree->look_down(_tag, 'tr', sub {
	$_->text() =~ m/Overall\s+Quality\*/;
				     }
	);
    my @ratingRowCells = $ratingRow->look_down(_tag, 'td');
    my $rating = $ratingRowCells[3]->text();

    print $self->{OUTHANDLE} "$doctorId\t$lastName\t$firstName\t$rating\n";
}

1;
