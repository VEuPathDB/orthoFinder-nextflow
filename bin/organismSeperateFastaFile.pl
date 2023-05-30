#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$outputDir, $fastaSubsetSize);

&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir,
            "fastaSubsetSize=i"=> \$fastaSubsetSize);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my $counter = 0;
my $organism;
while (my $line = <$data>) {
    if ($line =~ /^>(.+)\|/) {
	if ($counter == 0) {
	    $counter +=1;
	    $organism = $1;
            open(OUT,">$outputDir/$1");
	    print OUT $line;
        }
        elsif ($organism eq $1) {
	    print OUT $line;
	}
	else {
	    $organism = $1;
            close OUT;
	    open(OUT,">$outputDir/$1");
	    print OUT $line;
	}
    }
    else {
 	print OUT $line;
    }   
}	
