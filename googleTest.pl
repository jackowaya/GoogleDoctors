use WWW::Mechanize;
use 5.10.0;
use strict;
use warnings;

my $mech = new WWW::Mechanize;

my $option = shift; 

#you may customize your google search by editing this url (always end it with "q=" though)
my $google = 'http://www.google.com/search?q='; 
my @dork = ("this is my search one","this is my search two"); 

#declare necessary variables
my $max = 0;
my $link;
my $sc = scalar(@dork);

#start the main loop, one itineration for every google search
for my $i ( 0 .. $sc ) {

	#loop until the maximum number of results chosen isn't reached
	while ( $max <= $option ) {
		#say $google . $dork[$i] . "&start=" . $max;
		$mech->get( $google . $dork[$i] . "&start=" . $max );

		#get all the google results
		foreach $link ( $mech->links() ) {
			my $google_url = $link->url;
			if ( $google_url !~ /^\// && $google_url !~ /google/ ) {
			say $google_url;
	}
			}
			 $max += 10;
		}


	}