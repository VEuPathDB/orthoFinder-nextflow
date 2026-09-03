#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

For the OrthoFinder incremental build path: drops any sequence belonging to
an outdated organism from a proteome fasta.

The cached previous-run proteome (previousFullProteome) is otherwise just
concatenated onto this run's freshly-read proteome for the reprocessed
organisms (combineProteomes is a plain cat, no dedup) -- without this
filter, an organism's stale, no-longer-current sequences would accumulate
in the combined proteome forever, every incremental run. Since that combined
proteome feeds the diamond database used for *future* best-hit reassignment
(ortho<buildVersion>db.dmnd), a stale sequence sitting in it could end up
being returned as a future run's best hit -- an ID that no longer exists in
the organism's actual current proteome.

=head1 Input Parameters

=over 4

=item proteome

Fasta to filter (e.g. the cached previousFullProteome)

=item proteinToOrganism

TSV mapping "<proteinId>\t<organismAbbrev>"

=item outdatedOrganisms

One organism abbreviation per line -- sequences belonging to these are dropped

=item output

Filtered fasta

=back

=cut

my ($proteome, $proteinToOrganism, $outdatedOrganisms, $output);

&GetOptions("proteome=s" => \$proteome,
            "proteinToOrganism=s" => \$proteinToOrganism,
            "outdatedOrganisms=s" => \$outdatedOrganisms,
            "output=s" => \$output);

my %outdatedOrganism;
if (-e $outdatedOrganisms) {
    open(my $oh, '<', $outdatedOrganisms) || die "Could not open file $outdatedOrganisms: $!";
    while (my $line = <$oh>) {
        chomp $line;
        next unless length($line);
        $outdatedOrganism{$line} = 1;
    }
    close($oh);
}

my %proteinOrganism;
open(my $ph, '<', $proteinToOrganism) || die "Could not open file $proteinToOrganism: $!";
while (my $line = <$ph>) {
    chomp $line;
    my ($protein, $organism) = split(/\t/, $line);
    $proteinOrganism{$protein} = $organism;
}
close($ph);

open(my $inFh, '<', $proteome) || die "Could not open file $proteome: $!";
open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

my $keep = 1;
while (my $line = <$inFh>) {
    if ($line =~ /^>(\S+)/) {
        my $id = $1;
        my $organism = $proteinOrganism{$id};
        # Unknown organism (not in the map) is kept, not dropped -- same fallback
        # filterStableGroups.pl uses, safer than silently discarding data we
        # can't actually confirm is stale.
        $keep = !(defined $organism && $outdatedOrganism{$organism});
    }
    print $outFh $line if $keep;
}
close($inFh);
close($outFh);
