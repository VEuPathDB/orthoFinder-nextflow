#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$outputDir);

&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my $counter = 0;
my $organism;

# Foreach line in peripheral fasta
while (my $line = <$data>) {
    # If it is a def line
    if ($line =~ /^>(\w{4})\|/ || $line =~ /^>(\w{4}-old)\|/) {
	# Retrieve current organism
	my $currentOrganism = $1;
	# If first organism in file
	if ($counter == 0) {
	    $counter +=1;
	    $organism = $currentOrganism;
	    # Open the organism output file
            open(OUT,">$outputDir/${organism}.fasta");
	    print OUT $line;
        }
	# While the same organism, print out to same file
        elsif ($organism eq $currentOrganism) {
	    print OUT $line;
	}
	# Different organism, reset the organism and print out to new organism file
	else {
	    $organism = $currentOrganism;
            close OUT;
	    open(OUT,">$outputDir/${organism}.fasta");
	    print OUT $line;
	}
    }
    # Is a sequence, always follows defline so just print to current output
    else {
 	print OUT $line;
    }   
}	
