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
    if ($line =~ /^(>\w{4}\|)(.+)/ || $line =~ /^(>\w{4}-old\|)(.+)/) {
	my $fixOrganism = $1;
	$fixOrganism =~ s/>//g;
	$fixOrganism =~ s/\|//g;
	print $fixOrganism;
	if ($counter == 0) {
	    $counter +=1;
	    $organism = $fixOrganism;
            open(OUT,">$outputDir/$organism");
	    print OUT $line;
        }
        elsif ($organism eq $fixOrganism) {
	    print OUT $line;
	}
	else {
	    $organism = $fixOrganism;
            close OUT;
	    open(OUT,">$outputDir/$organism");
	    print OUT $line;
	}
    }
    else {
 	print OUT $line;
    }   
}	
