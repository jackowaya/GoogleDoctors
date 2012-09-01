package SubparserManager;
# Handles the subparsers available for doctor files in one convenient location.
use strict;

use Parsers::RateMdsParser;
use Parsers::VitalsParser;
use Parsers::HealthGradesParser;
use Parsers::YelpParser;
use Parsers::YahooLocalParser;
use Parsers::InsiderPagesParser;
use Parsers::WellnessParser;
use Parsers::GoogleMapsParser;
use Parsers::CitySearchParser;
use Parsers::LifescriptParser;
use Parsers::AvvoParser;
use Parsers::VimoParser;
use Parsers::EverydayHealthParser;
use Parsers::ThirdAgeParser;
use Parsers::UCompareParser;
use Parsers::BookHealthcareParser;
use Parsers::ZocDocParser;
use Parsers::SuperPagesParser;

sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

sub getSubparsers {
    # Gets a hash of subparser name -> subparser for a given directory.
    my $self = shift;
    my $resultDir = shift;
    my %subparsers = (
	"ratemds", RateMdsParser->new($resultDir),
	"vitals", VitalsParser->new($resultDir),
	"healthgrades", HealthGradesParser->new($resultDir),
	"yelp", YelpParser->new($resultDir),
	"yahoo", YahooLocalParser->new($resultDir),
	"insiderpages", InsiderPagesParser->new($resultDir),
	"wellness", WellnessParser->new($resultDir),
	"googlemaps", GoogleMapsParser->new($resultDir),
	"citysearch", CitySearchParser->new($resultDir),
	"lifescript", LifescriptParser->new($resultDir),
	"avvo", AvvoParser->new($resultDir),
	"vimo", VimoParser->new($resultDir),
	"everydayhealth", EverydayHealthParser->new($resultDir),
	"thirdage", ThirdAgeParser->new($resultDir),
	"ucompare", UCompareParser->new($resultDir),
	"bookhealthcare", BookHealthcareParser->new($resultDir),
	"zocdoc", ZocDocParser->new($resultDir),
	"superpages", SuperPagesParser->new($resultDir)
    );
    return %subparsers;
}

1;
