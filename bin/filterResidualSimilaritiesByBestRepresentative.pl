#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Filter residual group similarity files by only storing pairwise results that involve sequences being blasted against the best representative of the group to which they were assigned.

=head1 Input Parameters

=over 4

=item bestReps 

Tsv file containing a group ID and the sequence that best represents it.

=item singletons Tsv file containing a group ID and the singleton sequence that represents it (and is the only sequence contained in it)

=back 

=cut

my ($bestReps, $singletons);

&GetOptions("bestReps=s"=> \$bestReps,
            "singletons=s"=> \$singletons);

# Open file that contains ids of best reps and their group.
open(my $data, '<', $bestReps) || die "Could not open file $bestReps: $!
";

# Open singleton file so we can identify singletons.
open(my $single, '<', $singletons) || die "Could not open file $singletons: $!";

# Make array to hold all groups that are singletons.
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

    print "Processing Group $group\n";
    
    # If the group is a singleton, we just make an empty file, as this group does not have any non self or internal blast results to the best rep
    open(OUT, ">${group}_bestRep.tsv") or die "Cannot open file ${group}_bestRep.tsv for writing:$!";
    if ( grep( /^$group/, @singletonGroups ) ) {
        close OUT
    }
    
    # If the group is not a singleton go get all pairwise blast results that involve the best representative and output it to a groups file
    else {
	
        # We want only where the seqId is in the 2nd column to avoid duplicate values/rows.
        open(IN, "< ${group}.sim") or die "cannot open file ${group}.sim for reading: $!";

	# For each row of similarity results.
        while(<IN>) {

	    # If subject sequence is the group best representative, store the result.
            if(/\t${seqID}\t/) {
                print OUT $_;
            }
        }

        close IN;
        close OUT;
        `rm ${group}.sim`;
    }
}

close $data;
