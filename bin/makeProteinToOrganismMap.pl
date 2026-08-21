#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Build a protein-ID -> organism-abbreviation mapping from OrthoFinder's own
SpeciesIDs.txt/SequenceIDs.txt. This is organism-boundary information that is
always reliable regardless of whether a proteome's own sequence headers embed
an organism prefix (only UniProt-sourced proteomes follow the `abbrev|id`
convention; proteomes from component sites do not).

=head1 Input Parameters

=over 4

=item speciesIds

OrthoFinder's SpeciesIDs.txt (format: "<idx>: <organismAbbrev>.fasta").

=item sequenceIds

OrthoFinder's SequenceIDs.txt (format: "<speciesIdx>_<seqIdx>: <realId> ...").

=item output

Output TSV: one row per sequence, "<realId>\t<organismAbbrev>".

=back

=cut

my ($speciesIds, $sequenceIds, $output);

&GetOptions("speciesIds=s" => \$speciesIds,
            "sequenceIds=s" => \$sequenceIds,
            "output=s" => \$output);

open(my $spFh, '<', $speciesIds) || die "Could not open file $speciesIds: $!";

my %speciesIdxToAbbrev;
while (my $line = <$spFh>) {
    chomp $line;
    if ($line =~ /^(\d+):\s*(\S+)$/) {
        my ($idx, $fastaFile) = ($1, $2);
        (my $abbrev = $fastaFile) =~ s/\.fasta$//;
        $speciesIdxToAbbrev{$idx} = $abbrev;
    }
}
close($spFh);

open(my $seqFh, '<', $sequenceIds) || die "Could not open file $sequenceIds: $!";
open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

while (my $line = <$seqFh>) {
    chomp $line;
    if ($line =~ /^(\d+)_\d+:\s*(\S+)/) {
        my ($speciesIdx, $realId) = ($1, $2);
        my $abbrev = $speciesIdxToAbbrev{$speciesIdx};
        die "No organism abbrev found for species index $speciesIdx (from line: $line)" unless $abbrev;
        print $outFh "$realId\t$abbrev\n";
    }
    else {
        die "Improper SequenceIDs.txt format: $line";
    }
}
close($seqFh);
close($outFh);
