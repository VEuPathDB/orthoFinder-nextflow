#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
#use List::Util qw( reduce );

use Data::Dumper;

my ($groupFile);

&GetOptions("groupFile=s"=> \$groupFile, # Pairwise blast results per group
            );

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
    #push( @{$values{$qseq}}, $evalue);

    $values{$qseq}->{sum} += $evalue;
    $values{$qseq}->{total}++;
}

my %seqAvg;

my $minValue = 1000000000;

my $bestRepresentative;

# For every query sequence
foreach my $qseq (keys %values) {
    my $avg = $values{$qseq}->{sum} / $values{$qseq}->{total} ;
    if($avg <= $minValue) {
        $bestRepresentative = $qseq;
        $minValue = $avg;
    }
}

#my $bestRepresentative = reduce { $seqAvg{$a} <= $seqAvg{$b} ? $a : $b } keys %seqAvg;
#open(OUT,">$outputFile")  or die "Cannot open file $outputFile For writing: $!";
print "${group}\t${bestRepresentative}\n";
#close OUT;
