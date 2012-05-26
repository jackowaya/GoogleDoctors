package InsiderPagesParser;
use Parsers::DoctorFileParser;
@ISA = ("DoctorFileParser");

# Parser class for insider pages. Gets: doctorID, Review-Lastname, Review-Firstname, rating, number-of-ratings
# To use this, you must call init and teardown yourself

use strict;
use HTML::Tree;
use HTML::TreeBuilder;
use Parsers::ParserCommon;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(shift);
    bless($self, $class);
    return $self;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
   
    return $url =~ m/insiderpages\.com/i;
}

sub outputFilename {
    return "insiderPagesResults.txt";
}

sub pageName {
    return "Insider Pages";
}

sub getNameFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $nameElem = $tree->look_down('class', 'org fn business_card_name');

    if (!$nameElem) {
	print STDERR "Bad InsiderPages page $path\n";
	return "--", "--";
    }

    my $fullName = $nameElem->as_text();

    return ParserCommon::parseName($fullName);

}

sub getRatingFromTree {
    my $self = shift;
    my $tree = shift;
    my $path = shift;

    my $ratingBlock = $tree->look_down(sub {
	$_[0]->attr('class') eq 'rating_box' &&
	    !$_[0]->look_up('id', 'search_results')
				       });
    my $rating = "--";
    my $ratingCount = 0;
    if ($ratingBlock) {
	my $ratingElem = $ratingBlock->look_down('_tag', 'abbr');
	$rating = $ratingElem->attr('title') if $ratingElem;
	my $countElem = $ratingBlock->look_down('class', 'count');
	$ratingCount = $countElem->as_text() if $countElem;
    }

    return $rating, $ratingCount;
}

1;
