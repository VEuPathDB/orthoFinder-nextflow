#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($species0File, $species1File, $diamondFile, $outputFile);

&GetOptions("diamondFile=s" => \$diamondFile,
            "species0File=s" => \$species0File,
            "species1File=s" => \$species1File,
            "outputFile=s" => \$outputFile,
           );

my %species0Orthologs = &makeOrthologsFromFile($species0File);
my %species1Orthologs = &makeOrthologsFromFile($species1File);

open(BLAST, $diamondFile) or die "Cannot open file $diamondFile for reading: $!";
open(OUT, ">$outputFile") or die "Cannot open $outputFile for writing: $!";

while(<BLAST>) {
    chomp;

    # Split pairwise blast results
    my @a = split(/\t/, $_);

    # filter out self-self
    next if($a[0] eq $a[1]);

    # If sequences are in the same group
    if($species0Orthologs{$a[0]} && $species0Orthologs{$a[0]} eq $species1Orthologs{$a[1]}) {
        unshift @a, $species0Orthologs{$a[0]};
        print OUT join("\t", @a) . "\n";
    }
}

close BLAST;
close OUT;

# ===================== Subroutines ===================================

sub makeOrthologsFromFile {
    my ($speciesFile) = @_;
    my %speciesOrthologs;
    open(SPF, $speciesFile) or die "Cannot open file $speciesFile for reading: $!";
    while(<SPF>) {
        chomp;
        my ($og, $seq) = split(/\t/, $_);
        $speciesOrthologs{$seq} = $og;
    }
    close SPF;
    return %speciesOrthologs;
}
