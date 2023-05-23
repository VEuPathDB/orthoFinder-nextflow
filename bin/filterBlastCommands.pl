#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$outputDir);

&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir);

open(my $data, '<', $input) || die "Could not open file $input: $!";
#open(OUT,">$output");

my $counter = 0;
while (my $line = <$data>) {
    chomp $line;
    open(OUT,">$outputDir/command$counter.txt");
    print OUT $line;
    close OUT;
    $counter += 1;
}	
