#!/usr/bin/perl

use strict;

use Getopt::Long;

my ($outdated, $cachedSpeciesMapping, $cachedSequenceMapping, $newSpeciesMapping, $newSequenceMapping, $output);

&GetOptions("outdated=s"=> \$outdated,
            "cachedSpeciesMapping=s" => \$cachedSpeciesMapping,
            "cachedSequenceMapping=s" => \$cachedSequenceMapping,
            "newSpeciesMapping=s" => \$newSpeciesMapping,
            "newSequenceMapping=s" => \$newSequenceMapping,
            "output=s" => \$output
    );


open(OUT, ">$output") or die "cannot open file $output for writing: $!";

open(FILE, $outdated) or die "cannot open file $outdated for reading: $!";

my %outdated;
while(<FILE>) {
    chomp;
    $outdated{$_} = 1;

    print OUT $_ . "\n";
}
close FILE;

my %newSpecies;
open(NEW, $newSpeciesMapping) or die "cannot open file $newSpeciesMapping for reading: $!";
while(<NEW>) {
    chomp;
    my ($organismId, $organismName) = split(/: /, $_);
    $newSpecies{$organismName} = $organismId;
}
close NEW;

open(CACHE, $cachedSpeciesMapping) or die "cannot open file $cachedSpeciesMapping for reading: $!";
while(<CACHE>) {
    chomp;
    my ($organismId, $organismName) = split(/: /, $_);

    # don't read from cache if outdated
    next if($outdated{$organismName});

    my $newOrganismId = $newSpecies{$organismName};
    unless(defined $newOrganismId) {
        print OUT $organismName . "\n";
        next;
    }

    if(&organismIsOutdated($organismId, $newOrganismId, $cachedSequenceMapping, $newSequenceMapping)) {
        print OUT $organismName . "\n";
    }
}
close CACHE;

sub organismIsOutdated {
    my ($cachedOrganismId, $newOrganismId, $cachedSequenceMapping, $newSequenceMapping) = @_;

    my $cachedSeqIds = `grep ${cachedOrganismId}_ ${cachedSequenceMapping} |cut -f 2 -d ' '`;

    print "grep ${newOrganismId}_ ${newSequenceMapping} |cut -f 2 -d ' '\n";
    my $newSeqIds = `grep ${newOrganismId}_ ${newSequenceMapping} |cut -f 2 -d ' '`;

    if($cachedSeqIds eq $newSeqIds) {
        return 0;
    }

    return 1;
}

1;
