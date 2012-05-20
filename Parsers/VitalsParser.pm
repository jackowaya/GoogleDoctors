package VitalsParser;
use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Parser class for vitals.com. Gets: doctorID, Review-Lastname, Review-Firstname, rating
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
    open(MYOUT, $self->{RESULTDIR} . "/vitalsResults.txt", "w");
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

    my $reviewSection = $tree->look_down('id', 'review_section');
    my $nameSection = $reviewSection->look_down(_tag, 'h2');

    my $fullName = $nameSection->text();
    $fullName =~ s/\s+Doctor\s+Ratings\s*$//;
    my ($firstName, $lastName) = parseName($fullName);

    my $ratingSection = $reviewSection->look_down('class', 'value');
    my $rating = $ratingSection->text();

    print $self->{OUTHANDLE} "$doctorId\t$lastName\t$firstName\t$rating\n";
}
1;
