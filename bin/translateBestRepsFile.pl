#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestReps,$sequenceIds,$outputFile);

&GetOptions("bestReps=s"=> \$bestReps,
	    "sequenceIds=s"=> \$sequenceIds,
            "outputFile=s"=> \$outputFile);

open(SEQ, '<', $sequenceIds) || die "Could not open file $sequenceIds: $!";
my %sequenceIdsMap;
while (my $line = <SEQ>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s(\S+)/) {
	my $internal = $1;
	my $actual = $2;
        $sequenceIdsMap{$internal} = $actual;
    }
    else {
        die "Improper sequence id file format: $!";
    }
}
close SEQ;

open(MAP, '<', $bestReps) || die "Could not open file $bestReps: $!";
open(OUT, '>>', $outputFile) || die "Could not open file $outputFile: $!";

# Create hash to hold group and best rep id assignments
my %bestRepsMap;
while (my $line = <MAP>) {
    chomp $line;
    my ($group, $repseq) = split(/\t/, $line);
    if ($repseq !~ /^\d+\_\d+/) {
        print OUT "$group\t$repseq\n";
    }
    else {
        print OUT "$group\t$sequenceIdsMap{$repseq}\n";
    }
}
close MAP;
close OUT;
		   
1;
