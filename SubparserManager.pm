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
	"citysearch", CitySearchParser->new($resultDir)
    );
    return %subparsers;
}

1;
