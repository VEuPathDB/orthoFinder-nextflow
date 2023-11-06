#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Take a input file of pairwise similarity results of an organism proteome to the core best reps database, and the groups file indicating to which groups these sequences were assigned. Separate this file into a similarity file per group, only containing results between sequences assigned to that group and the groups best representative.

=head1 Input Parameters

=over 4

=item similarity

The organism specific specific pairwise results file

=back

=over 4

=item groups

A file containing the list of peripheral sequences and their group assignments

=back

=cut

my ($similarity,$groups);

&GetOptions("similarity=s"=> \$similarity, # Sorted diamond similarity results
            "groups=s"=> \$groups); # Sorted group assignments

open(my $group, '<', $groups) || die "Could not open file $groups: $!";
open(my $sim, '<', $similarity) || die "Could not open file $similarity: $!";

# Make hash to store sequence group assignments
my %seqToGroup;

# For each line in groups file
while (my $line = <$group>) {
    chomp $line;
    my ($seq,$groupId) = split(/\t/, $line);
    # Record the group assignment for each sequence
    $seqToGroup{$seq} = $groupId;
}
close $group;

my $currentGroupId = "";
while (my $line = <$sim>) {
    chomp $line;
    my ($seq,$groupId, @rest) = split(/\t/, $line);

    # Skip result unless shared between sequence and the best representative of it's group assignment
    next unless($seqToGroup{$seq} eq $groupId);

    # If same group that's currently opened, output.
    if ($groupId eq $currentGroupId) {
        print OUT "$line\n";
        next;
    }

    # Else, close current output file. Open new group file and output
    close OUT if($currentGroupId);
    $currentGroupId = $groupId;
    open(OUT, ">${groupId}_bestRep.tsv") || die "Could not open file ${groupId}_bestRep.tsv: $!";
    print OUT "$line\n";
}

close $sim;
close OUT;
