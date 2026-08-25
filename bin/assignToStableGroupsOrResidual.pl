#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Incremental-build counterpart to assignGroupsForPeripherals.pl: assign a
changed/removed/new-organism sequence to whichever stable group (core OR
residual) its single best Diamond hit belongs to. Identical best-hit logic to
assignGroupsForPeripherals.pl, but reads a combined stable-groups file that
may contain both core ("OG...") and residual ("OGR...") group IDs, where
assignGroupsForPeripherals.pl only recognizes core ("OG\d+_\d+") IDs. A
sequence with no hit (or whose only hit(s) fell in a filtered-out/outdated
group) is simply absent from the output, exactly as in the original script --
callers determine "unassigned" (X) the same way peripheralWorkflow already
does, via makeResidualAndPeripheralFastas.

=head1 Input Parameters

=over 4

=item result

File containing diamond similarity results (sequences being reassigned vs. the stable-groups database).

=item output

Output file: "<seqId>\t<groupID>" for every sequence that matched a stable group.

=item groupFile

Filtered, combined core+residual stable groups file ("GROUPID: seq1 seq2 ...").

=back

=cut

my ($result, $output, $groupFile);

&GetOptions("result=s" => \$result,
            "output=s" => \$output,
            "groupFile=s" => \$groupFile);

open(my $data, '<', $result) || die "Could not open file $result: $!";
open(OUT, ">$output");
open(GRP, "<$groupFile");

# Making a hash to hold stable (core + residual) group assignments.
my %stableGroupAssignments;

foreach my $line (<GRP>) {
    chomp $line;
    next unless length($line);

    if ($line =~ /^(\S+):\s(.+)/) {
        my $groupID = $1;
        my @seqArray = split(/\s+/, $2);

        foreach my $seq (@seqArray) {
            $stableGroupAssignments{$seq} = $groupID;
        }
    }
    else {
        die "Improper group file format: $line";
    }
}

# Creating a hash to hold sequences and the IDs of the subject from their pair with the best e-value.
my %seqBestHit;

while (my $line = <$data>) {
    chomp $line;

    my @lineAr = split(/\t/, $line);

    my $qseq = $lineAr[0];
    my $sseq = $lineAr[1];
    my $evalue = $lineAr[10];

    unless ($seqBestHit{$qseq}) {
        $seqBestHit{$qseq}->{evalue} = $evalue;
        $seqBestHit{$qseq}->{sseq} = $sseq;
    }

    if ($seqBestHit{$qseq}->{evalue} > $evalue) {
        $seqBestHit{$qseq}->{evalue} = $evalue;
        $seqBestHit{$qseq}->{sseq} = $sseq;
    }
}

# For each sequence, print out its group assignment -- but only if its best hit
# actually landed on a sequence that's still part of a stable group (a hit on a
# sequence that got filtered out for being in an outdated/removed organism is
# treated the same as no hit at all: fall through to residual/unassigned).
foreach my $seq (keys %seqBestHit) {
    my $seqBestMatch = $seqBestHit{$seq}->{sseq};
    my $groupID = $stableGroupAssignments{$seqBestMatch};
    print OUT "$seq\t$groupID\n" if $groupID;
}
