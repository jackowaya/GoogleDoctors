package ParserCommon;

# Some utility functions
use strict;

sub parseName {
    # Parses a firstname lastname styled name into firstname and last name.
    my $fullName = shift;
    
    # Take off anything after a comma
    $fullName =~ s/,.*//;
    # Take off MD if necessary
    $fullName =~ s/\s+M\.?D\.?\s+$//i;
    # Last name is after last space. First name is everything else
    my @nameParts = split(/\s+/, $fullName);
    my $lastName = pop(@nameParts);
    return join(' ', @nameParts), $lastName;
}

sub tabSeparate {
    # Takes an array ref. Returns tab separated values followed by a newline.
    my $output = "";
    my $tmp;
    my @vals = @{$_[0]};
    for (my $i = 0; $i < scalar(@vals) - 1; $i++) {
	$tmp = $vals[$i];
	if (!defined($tmp)) { 
	    print STDERR "Got undefined value $output";
	}
	$tmp =~ s/\s+/ /g;
	$output .= $tmp . "\t";
    }
    $tmp = $vals[scalar(@vals) - 1];
    $tmp =~ s/\s+/ /g;
    $output .= $tmp . "\n";

    return $output;
}

1;
