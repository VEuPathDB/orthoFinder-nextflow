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

=item outputCore

Merged core+peripheral best-reps output.

=item outputResidual

Merged residual best-reps output.

=back

=cut

my ($cachedCoreBestReps, $cachedResidualBestReps, $touchedBestReps, $outputCore, $outputResidual);

&GetOptions("cachedCoreBestReps=s" => \$cachedCoreBestReps,
            "cachedResidualBestReps=s" => \$cachedResidualBestReps,
            "touchedBestReps=s" => \$touchedBestReps,
            "outputCore=s" => \$outputCore,
            "outputResidual=s" => \$outputResidual);

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
            next if $touched->{$groupId}; # superseded by a fresh recomputation below
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
