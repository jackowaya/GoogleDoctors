#!/usr/bin/perl -w

# Example code from Chapter 1 of /Perl and LWP/ by Sean M. Burke
# http://www.oreilly.com/catalog/perllwp/
# sburke@cpan.org

#require 5;
use strict;
#use warnings;

use Text::CSV;
use LWP::Simple;
use HTML::Tree;
use HTML::TreeBuilder;
use WWW::Mechanize;
use URI::Escape;
my $url = "http://videos.mitrasites.com/william-richmond-(physician).html";
#my $url = "http://videos.mitrasites.com/william-richmond-%28physician%29.html";

my $mech = new WWW::Mechanize;

# Get the first page and its links, then the next page, then pause.
#open(FO, ">" . $filename) or die "Cannot open file $filename $!";
	
#$content = get($myURI);
$mech->get($url);	
#print FO $content;
print $mech->content();
			
	