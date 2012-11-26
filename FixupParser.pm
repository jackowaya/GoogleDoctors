package FixupParser;

use ParsingFramework::FileParser;
@ISA = ("FileParser");

# Fixup parser - Parses the files for a single parser.
# To use this, you must call init and teardown yourself

use strict;
use URI::Escape;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{INITED} = 0;
    $self->{PARSER} = shift;
    bless($self, $class);
    return $self;
}

sub init() {
    # Initializes this parser and sub-parser
    my $self = shift;
    $self->{PARSER}->init();
    $self->{INITED} = 1;
}

sub teardown() {
    # Tears down this parser and sub-parser.
    my $self = shift;
    $self->{PARSER}->teardown();
    $self->{INITED} = 0;
}

sub canParseUrl {
    my $self = shift;
    my $url = shift;
    return $self->{PARSER}->canParseUrl($url);
}

sub parse {
    my $self = shift;
    die "Cannot parse before init is called" unless $self->{INITED};
    my $path = shift;
    
    if ($path =~ m/(\d+)\.(\d+)\.(\d+)\.html/i) {
	my $docId = $1;
	$self->{PARSER}->parse($docId, $path);
    }
}

1;
