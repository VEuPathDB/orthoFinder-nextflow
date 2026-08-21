#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Filter a touched group's self-diamond .sim file down to core-organism-only
pairs (both query and subject from a core organism), needed to recompute the
"core-only" group stats variant for touched groups.

=head1 Input Parameters

=over 4

=item simFile

A group's self-diamond output (diamond -f 6 format).

=item proteinToOrganism

TSV mapping "<proteinId>\t<organismAbbrev>".

=item coreOrganisms

One core organism abbreviation per line.

=item output

Filtered .sim file, same format, core-organism pairs only.

=back

=cut

my ($simFile, $proteinToOrganism, $coreOrganisms, $output);

&GetOptions("simFile=s" => \$simFile,
            "proteinToOrganism=s" => \$proteinToOrganism,
            "coreOrganisms=s" => \$coreOrganisms,
            "output=s" => \$output);

open(my $mapFh, '<', $proteinToOrganism) || die "Could not open file $proteinToOrganism: $!";
my %proteinOrganism;
while (my $line = <$mapFh>) {
    chomp $line;
    my ($protein, $organism) = split(/\t/, $line);
    $proteinOrganism{$protein} = $organism;
}
close($mapFh);

open(my $coreFh, '<', $coreOrganisms) || die "Could not open file $coreOrganisms: $!";
my %isCoreOrganism;
while (my $line = <$coreFh>) {
    chomp $line;
    next unless length($line);
    $isCoreOrganism{$line} = 1;
}
close($coreFh);

open(my $simFh, '<', $simFile) || die "Could not open file $simFile: $!";
open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

while (my $line = <$simFh>) {
    my @fields = split(/\t/, $line);
    my ($qseq, $sseq) = @fields[0, 1];

    my $qOrganism = $proteinOrganism{$qseq};
    my $sOrganism = $proteinOrganism{$sseq};

    if (defined $qOrganism && defined $sOrganism && $isCoreOrganism{$qOrganism} && $isCoreOrganism{$sOrganism}) {
        print $outFh $line;
    }
}
close($simFh);
close($outFh);
