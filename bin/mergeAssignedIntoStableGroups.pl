#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Incremental-build counterpart to makeGroupsFile.pl: merge newly-assigned
sequences into the filtered stable groups file produced by
filterStableGroups.pl. Identical merge logic, but (like
filterStableGroups.pl/assignToStableGroupsOrResidual.pl) accepts both core
("OG...") and residual ("OGR...") group IDs, where makeGroupsFile.pl only
recognizes core ("OG\d+_\d+") IDs.

=head1 Input Parameters

=over 4

=item stableGroups

Filtered stable groups file (both core and residual groups; "GROUPID: seq1 seq2 ...").

=item assignments

Newly-assigned sequences: "<seqId>\t<groupID>" per line.

=item output

Merged groups file, same format as stableGroups.

=back

=cut

my ($stableGroups, $assignments, $output);

&GetOptions("stableGroups=s" => \$stableGroups,
            "assignments=s" => \$assignments,
            "output=s" => \$output);

open(my $assignFh, '<', $assignments) || die "Could not open file $assignments: $!";

my %newSeqsByGroup;
while (my $line = <$assignFh>) {
    chomp $line;
    next unless length($line);

    my ($sequence, $groupId) = split(/\t/, $line);
    push(@{$newSeqsByGroup{$groupId}}, $sequence);
}
close($assignFh);

open(my $stableFh, '<', $stableGroups) || die "Could not open file $stableGroups: $!";
open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

my %seenGroup;

while (my $line = <$stableFh>) {
    chomp $line;
    next unless length($line);

    if ($line =~ /^(\S+):\s(.+)/) {
        my ($groupId, $seqString) = ($1, $2);
        $seenGroup{$groupId} = 1;

        my @allSeqs = split(/\s+/, $seqString);
        if ($newSeqsByGroup{$groupId}) {
            push(@allSeqs, @{$newSeqsByGroup{$groupId}});
        }

        print $outFh "$groupId: " . join(" ", @allSeqs) . "\n";
    }
    else {
        die "Improper stable groups file format: $line";
    }
}
close($stableFh);
close($outFh);
