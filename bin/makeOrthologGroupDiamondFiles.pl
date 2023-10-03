#!/usr/bin/perl

use strict;

use Getopt::Long;

use Data::Dumper;

my ($species0File, $species1File, $diamondFile, $outputFile);

&GetOptions("diamondFile=s" => \$diamondFile,
            "species0File=s" => \$species0File,
            "species1File=s" => \$species1File,
            "outputFile=s" => \$outputFile,
    );

open(SP0, $species0File) or die "Cannot open file $species0File for reading: $!";
open(SP1, $species1File) or die "Cannot open file $species0File for reading: $!";

my %species0Orthologs;
my %species1Orthologs;

while(<SP0>) {
    chomp;
    my ($og, $seq) = split(/\t/, $_);
    $species0Orthologs{$seq} = $og;
}

while(<SP1>) {
    chomp;
    my ($og, $seq) = split(/\t/, $_);
    $species1Orthologs{$seq} = $og;
}
close SP0;
close SP1;


open(BLAST, $diamondFile) or die "Cannot open file $diamondFile for reading: $!";
open(OUT, ">$outputFile") or die "Cannot open $outputFile for writing: $!";

while(<BLAST>) {
    chomp;

    my @a = split(/\t/, $_);

    if($species0Orthologs{$a[0]} && $species0Orthologs{$a[0]} eq $species1Orthologs{$a[1]}) {
        unshift @a, $species0Orthologs{$a[0]};
        print OUT join("\t", @a) . "\n";
    }
}

close BLAST;
close OUT;
