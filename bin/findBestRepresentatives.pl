#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use List::Util qw( reduce );

use Data::Dumper;

my ($groupFile, $outputFile);

&GetOptions("groupFile=s"=> \$groupFile, # Pairwise blast results per group
            "output_file=s" => \$outputFile);

my $QSEQ_COLUMN = 0;
my $EVALUE_COLUMN = 10;

open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";

# Retrieve group ID from groupFile
my $group = $groupFile;
$group =~ s/\.sim$//;

my %values;

while (my $line = <$data>) {
    chomp $line;

    # Get array of pairwise blast results
    my @lineAr = split(/\t/, $line);

    # Retrieve query sequence
    my $qseq = $lineAr[$QSEQ_COLUMN];

    # Retrieve evalue
    my $evalue = $lineAr[$EVALUE_COLUMN];

    # Make an array of evalues per query sequence
    push( @{$values{$qseq}}, $evalue);
}

my %seqAvg;

# For every query sequence
foreach my $qseq (keys %values) {
    my $sum = 0;
    my $pairCountPerQSeq = scalar @{$values{$qseq}};
    # Sum up all of the evalues
    foreach(@{$values{$qseq}}) {
        $sum += $_;
    }
    # Calculate average e-value per query sequence
    my $avg = $sum / $pairCountPerQSeq;
    $seqAvg{$qseq} = $avg;
}

my $bestRepresentative = reduce { $seqAvg{$a} <= $seqAvg{$b} ? $a : $b } keys %seqAvg;

open(OUT,">$outputFile")  or die "Cannot open file $outputFile For writing: $!";
print OUT "${group}\t${bestRepresentative}\n";
close OUT;

