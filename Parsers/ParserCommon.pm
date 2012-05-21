package ParserCommon;

# Some utility functions
use strict;

sub parseName {
    # Parses a firstname lastname styled name into firstname and last name.
    my $fullName = shift;
    
    # Take off anything after a comma
    $fullName =~ s/,.*//;
    # Last name is after last space. First name is everything else
    my @nameParts = split(/\s+/, $fullName);
    my $lastName = pop(@nameParts);
    return join(' ', @nameParts), $lastName;
}

1;
