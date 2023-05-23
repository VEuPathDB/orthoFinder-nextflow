#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$outputDir);

&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir);

open(my $data, '<', $input) || die "Could not open file $input: $!";

while (<$data>) {
    if (/^diamond\sblastp\s--ignore-warnings\s-d\s(.+)\s-q\s(.+)\s-o\s(.+)\/(Blast\d_\d.txt)\s--more-sensitive\s-p\s1\s--quiet\s-e\s0.001\s--compress/) {    
        my $dataPath = $1;
	my $queryPath = $2;
	my $outputFull = $3;
	my $outputFile = $4;
	open(OUT,">$outputDir/dataPath.txt");
	print OUT "$dataPath.dmnd";
	close OUT;
	open(OUT,">$outputDir/queryPath.txt");
	print OUT "$queryPath";
	close OUT;
	open(OUT,">$outputDir/outputPath.txt");
	print OUT "$outputFile";
	close OUT;
    }
    else {
	die;
    }
}
