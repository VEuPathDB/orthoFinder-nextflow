#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestReps, $blastFile,$outputFile);

&GetOptions("bestReps=s"=> \$bestReps,
            "blastFile=s"=> \$blastFile,
            "outputFile=s"=> \$outputFile);

# Open file that contains ids of best reps and their group.
open(my $best, '<', $bestReps) || die "Could not open file $bestReps: $!";

# Open blast file.
open(my $blast, '<', $blastFile) || die "Could not open file $blastFile: $!";

# Open output file.
open(my $out, '>', $outputFile) || die "Could not open file $outputFile: $!";

# Create hash to hold group and best rep id assignments
my %bestRepsMap;
while (my $line = <$best>) {
    chomp $line;
    my ($group, $repseq) = split(/\t/, $line);
    $bestRepsMap{$group} = $repseq;
}
close $best;

while (my $line = <$blast>) {
    chomp $line;
    my ($group, $qseq,$sseq,$evalue) = split(/\t/, $line);
    if (!$qseq || !$sseq) {
        die "Missing value for either qseq: $qseq or sseq: $sseq\n";
    }
    if ($bestRepsMap{$group} eq $sseq) {
	print $out "$group\t$qseq\t$sseq\t$evalue\n";
    }
}
close $blast;
close $out;
