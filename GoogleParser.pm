package GoogleParser;

use ParsingFramework::FileParser;
use Parsers::RateMdsParser;
use Parsers::VitalsParser;
use Parsers::HealthGradesParser;
@ISA = ("FileParser");

# Google parser - Wraps several different parsers - one that gets the links
# from google search results and several others for specific pages.
# This parser actually ignores many of the paths sent to it by parse, preferring to
# Determine which files are interesting based on the search results pages.
# Results are written to a folder specified at create time.
# To use this, you must call init and teardown yourself

use strict;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    my $self->{RESULTDIR} = shift;
    my $self->{INITED} = 0;
    my $self->{SUBPARSERS} = {
	'ratemds' => RateMdsParser->new(),
	'vitals' => VitalsParser->new(),
	'healthgrades' => HealthGradesParser->new()
    };
    bless($self, $class);
    return $self;
}

sub init() {
    # Initializes this parser and sub-parsers
    open(MYOUT, $self->{RESULTDIR} . "/searchResults.txt", "w");
    $self->{OUTHANDLE} = MYOUT;
    print $self->{OUTHANDLE} "ID\tResult Page\tResult Number\tLink\n";
    foreach my $k (keys($self->{SUBPARSERS})) {
	$self->{SUBPARSERS}{$k}->init();
    }
    $self->{INITED} = 1;
}

sub teardown() {
    # Tears down this parser and sub-parsers.
    close($self->{OUTHANDLE});
    foreach my $k (keys($self->{SUBPARSERS})) {
	$self->{SUBPARSERS}{$k}->teardown();
    }
    $self->{INITED} = 0;
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $path = shift;
    if ($path =~ m/(\w+-\d+)\.(\d+)\.(\d+)/) {
	# This is a google search reuslt page.
	my $docId = $1;
	my $page = $2;
	my $res = $3;
	my @links = getSubLinks("$infolder/$file");
	
	foreach my $link (@links) {
	    print "$docId\t$page\t$res\t$link\n";
	}
    }
}
1;
