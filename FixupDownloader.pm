package FixupDownloader;
use ParsingFramework::FileDownloader;
@ISA = ("FileDownloader");
# FixupDownloader is designed to download results for only a specific parser's use.
# It performs the following actions:
# * From searchResults.txt (made by GoogleParser), parse out links that the parser can handle
# * grab pages in inputlinks-parser.txt, save them in the output folder

use strict;

use HTML::Tree;
use HTML::TreeBuilder;
use WWW::Mechanize;
use URI::Escape;


sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->{FILES} = [];
    
    $self->{OUTPUTDIR} = shift;
    $self->{PARSER} = shift;

    bless($self, $class);
    return $self;
}

sub download {
    my $self = shift;

    my $i;
    my $myURI;
    my $filename;

    my $infile = shift;
    my $outfolder = $self->{OUTPUTDIR};

    open(IN, "<$infile") or die "Could not open input file $infile: $!";
    my @searchResults = <IN>;
    close(IN);

    foreach my $searchRes (@searchResults) {
	my @parts = split(/\t/, $searchRes);
	if ($parts[0] ne "ID") {
	    $myURI = $parts[3];

	    if ($self->{PARSER}->canParseUrl($myURI)) {
		$filename = "$outfolder/$parts[0].$parts[2].$parts[1].html";
		
		$self->downloadPage($myURI, $filename);
		sleep 15;
	    }
	}
    }

    print "done! Ta Da \n";

}

sub outputPaths {
    my $self = shift;
    opendir(DIR, $self->{OUTPUTDIR}) or die "Cannot open output dir $!";
    my @files = readdir(DIR);
    closedir(DIR);
    my @res;
    foreach my $file (@files) {
	if ($file !~ /^\.*$/) {
	    push(@res, $self->{OUTPUTDIR} . "/" . $file);
	}
    }
    return @res;

}

sub downloadPage {
    my $self = shift;
    my $url = shift;
    my $outfile = shift;

    my $mech = new WWW::Mechanize;
    eval {
	$mech->get($url);
		
	$mech->save_content($outfile);
	
	print "Wrote $url to $outfile\n";
    };
    if ($@) {
	print STDERR "ERROR Writing $url to $outfile: $@ - creating empty file\n";
	open(FO, ">" . $outfile);
	print FO "ERROR Downloading: $@\n";
	close(FO);
    }	
}
1;
