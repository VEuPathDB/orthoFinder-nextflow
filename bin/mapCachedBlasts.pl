#!/usr/bin/perl

use strict;

use Getopt::Long;

use File::Basename;

use Data::Dumper;

my ($outdated, $cachedSpeciesMapping, $cachedSequenceMapping, $newSpeciesMapping, $newSequenceMapping, $outputDir, $diamondCacheDir);

&GetOptions("outdated=s"=> \$outdated,
            "cachedSpeciesMapping=s" => \$cachedSpeciesMapping,
            "cachedSequenceMapping=s" => \$cachedSequenceMapping,
            "newSpeciesMapping=s" => \$newSpeciesMapping,
            "newSequenceMapping=s" => \$newSequenceMapping,
            "diamondCacheDir=s" => \$diamondCacheDir,
            "outputDir=s" => \$outputDir
    );

open(FILE, $outdated) or die "cannot open file $outdated for reading: $!";


unless(-e $cachedSpeciesMapping && -e $cachedSequenceMapping) {
    print STDERR "NO CACHE Mapping found.  Processing all pairs\n";
    exit;
}



my %outdated;
while(<FILE>) {
    chomp;
    $outdated{$_} = 1;
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
my %speciesMap;
while(<CACHE>) {
    chomp;
    my ($organismId, $organismName) = split(/: /, $_);

    # don't read from cache if outdated
    if($outdated{$organismName}) {
        print STDERR "WARN:  SKIP Organism $organismName defined in Outdated File";
        next ;
    }



    my $newOrganismId = $newSpecies{$organismName};
    unless(defined $newOrganismId) {
        print STDERR "WARN:  SKIP Organism $organismName as it no longer exists in this run of orthofinder";
        next;
    }

    if(&organismIsOutdated($organismId, $newOrganismId, $cachedSequenceMapping, $newSequenceMapping)) {
        print STDERR "WARN:  Unexpected skipping of organism $organismName";
    }

    # if we made it here, we can do the species mapping
    $speciesMap{$organismId} = $newOrganismId;
}
close CACHE;

my @cachedBlastFiles = glob "$diamondCacheDir/Blast*.txt";

foreach my $cachedBlastFile (@cachedBlastFiles) {



    my $cachedBlastFileBasename = basename $cachedBlastFile;

    #Blast1_0.txt
    my ($org1, $org2) = $cachedBlastFileBasename =~ /Blast(\d+)_(\d+)\.txt/;

    my $newOrg1 = $speciesMap{$org1};
    my $newOrg2 = $speciesMap{$org2};

    if(defined $newOrg1  && defined $newOrg2) {
        my $newBlastFileBasename = "Blast${newOrg1}_${newOrg2}.txt";
        open(BLASTIN, $cachedBlastFile) or die "Cannot open file $cachedBlastFile for reading: $!";
        open(BLASTOUT, ">$outputDir/$newBlastFileBasename") or die "Cannot open file $outputDir/$newBlastFileBasename for writing: $!";


        while(<BLASTIN>) {
            chomp;
            my @line = split(/\t/, $_);

            # this will replace the species part of the id with the mapped id
            $line[0] =~ s/^(\d+)/$speciesMap{$1}/;
            $line[1] =~ s/^(\d+)/$speciesMap{$1}/;

            print BLASTOUT join("\t", @line) . "\n";
        }

        close BLASTIN;
        close BLASTOUT;
    }
    else {
        die "Could not find species mapping for $org1 or $org2";
    }
}

sub organismIsOutdated {
    my ($cachedOrganismId, $newOrganismId, $cachedSequenceMapping, $newSequenceMapping) = @_;

    my $cachedSeqIds = `grep ${cachedOrganismId}_ ${cachedSequenceMapping} |cut -f 2 -d ' '`;
    my $newSeqIds = `grep ${newOrganismId}_ ${newSequenceMapping} |cut -f 2 -d ' '`;

    if($cachedSeqIds eq $newSeqIds) {
        return 0;
    }

    return 1;
}

1;
