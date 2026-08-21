#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Filter the previous run's core + residual group files down to just the
"stable" membership: drop any member sequence whose organism appears in the
outdated-organisms file (changed, removed, or -- via the caller's own
knowledge of the current proteome set -- simply no longer known). Groups left
with zero members after filtering are dropped entirely. Organism identity is
resolved via the persisted protein-id -> organism-abbrev map, not by parsing
sequence IDs (only UniProt-sourced proteomes embed organism in the ID).

=head1 Input Parameters

=over 4

=item fullGroupFile

Previous run's core+peripheral group file ("OG..." groups; "GROUPID: seq1 seq2 ...").

=item residualGroupFile

Previous run's residual group file ("OGR..." groups; same format).

=item proteinToOrganism

TSV mapping "<proteinId>\t<organismAbbrev>", covering every sequence in both group files.

=item outdatedOrganisms

One organism abbreviation per line -- organisms to drop.

=item output

Combined, filtered group file (both OG and OGR groups), same format as input.

=back

=cut

my ($fullGroupFile, $residualGroupFile, $proteinToOrganism, $outdatedOrganisms, $output);

&GetOptions("fullGroupFile=s" => \$fullGroupFile,
            "residualGroupFile=s" => \$residualGroupFile,
            "proteinToOrganism=s" => \$proteinToOrganism,
            "outdatedOrganisms=s" => \$outdatedOrganisms,
            "output=s" => \$output);

open(my $mapFh, '<', $proteinToOrganism) || die "Could not open file $proteinToOrganism: $!";
my %proteinOrganism;
while (my $line = <$mapFh>) {
    chomp $line;
    my ($protein, $organism) = split(/\t/, $line);
    $proteinOrganism{$protein} = $organism;
}
close($mapFh);

open(my $outdatedFh, '<', $outdatedOrganisms) || die "Could not open file $outdatedOrganisms: $!";
my %outdatedOrganism;
while (my $line = <$outdatedFh>) {
    chomp $line;
    next unless length($line);
    $outdatedOrganism{$line} = 1;
}
close($outdatedFh);

open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

foreach my $groupFile ($fullGroupFile, $residualGroupFile) {
    open(my $grpFh, '<', $groupFile) || die "Could not open file $groupFile: $!";

    while (my $line = <$grpFh>) {
        chomp $line;
        next unless length($line);

        if ($line =~ /^(\S+):\s(.+)/) {
            my ($groupId, $seqString) = ($1, $2);
            my @seqArray = split(/\s+/, $seqString);

            my @stableSeqs = grep {
                my $organism = $proteinOrganism{$_};
                if (!defined $organism) {
                    warn "No organism found for sequence $_ in group $groupId; keeping it as stable\n";
                    1;
                }
                else {
                    !$outdatedOrganism{$organism};
                }
            } @seqArray;

            if (@stableSeqs) {
                print $outFh "$groupId: " . join(" ", @stableSeqs) . "\n";
            }
        }
        else {
            die "Improper group file format in $groupFile: $line";
        }
    }
    close($grpFh);
}
close($outFh);
