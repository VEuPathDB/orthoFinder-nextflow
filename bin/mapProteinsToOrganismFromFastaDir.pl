#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Build a protein-ID -> organism-abbreviation mapping directly from a directory
of per-organism proteome fastas (one file per organism, named
"<organismAbbrev>.fasta"). This is used wherever organism boundaries are known
by file, not by OrthoFinder's own SpeciesIDs/SequenceIDs mapping (i.e. outside
of orthoFinderSetup) -- notably for peripheral proteomes, which are diamond-
searched per organism without ever going through OrthoFinder's own internal
ID assignment.

=head1 Input Parameters

=over 4

=item fastaDir

Directory containing one fasta file per organism, named "<organismAbbrev>.fasta".

=item output

Output TSV: one row per sequence, "<proteinId>\t<organismAbbrev>".

=back

=cut

my ($fastaDir, $output);

&GetOptions("fastaDir=s" => \$fastaDir,
            "output=s" => \$output);

opendir(my $dh, $fastaDir) || die "Could not open directory $fastaDir: $!";
my @fastas = grep { /\.fasta$/ } readdir($dh);
closedir($dh);

open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

foreach my $fastaFile (@fastas) {
    (my $abbrev = $fastaFile) =~ s/\.fasta$//;

    open(my $fh, '<', "$fastaDir/$fastaFile") || die "Could not open file $fastaDir/$fastaFile: $!";
    while (my $line = <$fh>) {
        if ($line =~ /^>(\S+)/) {
            print $outFh "$1\t$abbrev\n";
        }
    }
    close($fh);
}
close($outFh);
