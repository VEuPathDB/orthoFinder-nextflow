#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$outputDir, $fastaSubsetSize);

# JB: REmove this script.
# Reflow workflow should send tar file (tar.gz) of fasta files named by orgAbbrev.fasta


&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir
    );

open(my $data, '<', $input) || die "Could not open file $input: $!";

my $counter = 0;
my $organism;
while (my $line = <$data>) {
    if ($line =~ /^>(\w{4})\|(.+)/ || $line =~ /^>(\w{4}-old)\|(.+)/) {
        my $fixOrganism = $1;

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
