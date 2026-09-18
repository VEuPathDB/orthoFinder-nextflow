#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Merge freshly-recomputed best representatives for touched groups into the
previous run's cached best-representative mapping, splitting the result back
into separate core ("OG...") and residual ("OGR...") files -- since
downstream steps (postProcessingEntry) consume those separately.

=head1 Input Parameters

=over 4

=item cachedCoreBestReps

Previous run's cached core+peripheral best-reps file ("groupID\tseqID" per line).

=item cachedResidualBestReps

Previous run's cached residual best-reps file, same format.

=item touchedBestReps

Freshly-recomputed best-reps for touched groups (both core and residual mixed), same format.
Does NOT necessarily cover every group in touchedGroups -- a touched group that lost every
member this run (fully dropped by filterStableGroups.pl, e.g. all of its sequences belonged to
a reprocessed/outdated organism) has no fresh best rep to compute at all, and simply never
appears here.

=item touchedGroups

Full list of touched group IDs (one per line) -- every group that either lost or gained a
member this run, whether or not a fresh best rep was actually computed for it (see
touchedBestReps above). This, not touchedBestReps, is what determines which cached rows to
drop: a touched group with no entry in touchedBestReps no longer exists (rather than merely
being unchanged), so its cached row must be dropped with nothing to replace it -- carrying it
forward unchanged would leave a stale best-rep entry for a group that's gone.

=item outputCore

Merged core+peripheral best-reps output.

=item outputResidual

Merged residual best-reps output.

=back

=cut

my ($cachedCoreBestReps, $cachedResidualBestReps, $touchedBestReps, $touchedGroupsFile, $outputCore, $outputResidual);

&GetOptions("cachedCoreBestReps=s" => \$cachedCoreBestReps,
            "cachedResidualBestReps=s" => \$cachedResidualBestReps,
            "touchedBestReps=s" => \$touchedBestReps,
            "touchedGroups=s" => \$touchedGroupsFile,
            "outputCore=s" => \$outputCore,
            "outputResidual=s" => \$outputResidual);

open(my $touchedGroupsFh, '<', $touchedGroupsFile) || die "Could not open file $touchedGroupsFile: $!";
my %touchedGroupIds;
while (my $line = <$touchedGroupsFh>) {
    chomp $line;
    next unless length($line);
    $touchedGroupIds{$line} = 1;
}
close($touchedGroupsFh);

open(my $touchedFh, '<', $touchedBestReps) || die "Could not open file $touchedBestReps: $!";
my (%touchedCore, %touchedResidual);
while (my $line = <$touchedFh>) {
    chomp $line;
    next unless length($line);

    my ($groupId, $seqId) = split(/\t/, $line);
    if ($groupId =~ /^OGR/) {
        $touchedResidual{$groupId} = $seqId;
    }
    else {
        $touchedCore{$groupId} = $seqId;
    }
}
close($touchedFh);

sub mergeOne {
    my ($cachedFile, $touched, $outFile) = @_;

    my %seenGroup;

    open(my $outFh, '>', $outFile) || die "Could not open file $outFile for writing: $!";

    if (-e $cachedFile) {
        open(my $cachedFh, '<', $cachedFile) || die "Could not open file $cachedFile: $!";
        while (my $line = <$cachedFh>) {
            chomp $line;
            next unless length($line);

            my ($groupId, $seqId) = split(/\t/, $line);
            # Drop the cached row for ANY touched group, not just ones that got a fresh
            # replacement below -- a touched group absent from $touched (see touchedGroups
            # doc above) no longer exists, so its stale cached row must not survive.
            next if $touchedGroupIds{$groupId};
            $seenGroup{$groupId} = 1;
            print $outFh "$groupId\t$seqId\n";
        }
        close($cachedFh);
    }

    foreach my $groupId (keys %$touched) {
        print $outFh "$groupId\t" . $touched->{$groupId} . "\n";
    }

    close($outFh);
}

mergeOne($cachedCoreBestReps, \%touchedCore, $outputCore);
mergeOne($cachedResidualBestReps, \%touchedResidual, $outputResidual);
