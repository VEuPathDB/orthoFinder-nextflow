#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestReps, $singletons);

&GetOptions("bestReps=s"=> \$bestReps,
            "singletons=s"=> \$singletons);

# Open file that contains ids of best reps and their group
open(my $data, '<', $bestReps) || die "Could not open file $bestReps: $!";
# Open singleton file so we can identify singletons
open(my $single, '<', $singletons) || die "Could not open file $singletons: $!";

# Make array to hold all groups that are singletons
my @singletonGroups;
while (my $line = <$single>) {
    chomp $line;
    my ($group, $seqID) = split(/\t/, $line);
    push(@singletonGroups,$group);
}

# For each line in best representative file
while (my $line = <$data>) {
    chomp $line;
    # Get the group and sequence id
    my ($group, $seqID) = split(/\t/, $line);
    # If the group is a singleton, we just make an empty file, as this group does not have any non self blast results to the best rep
    if ( grep( /^$group/, @singletonGroups ) ) {
        `touch ${group}_bestRep.tsv`;
    }
    # If the group is not a singleton, go get all pairwise blast results that involve the best representative and output it to a groups file
    else {
        # we want only where the seqId is in the 2nd column to avoid dups
        `grep -P "\t${seqID}" ${group}.sim > ${group}_bestRep.tsv`;
    }
}

close $data;
