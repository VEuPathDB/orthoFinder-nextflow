#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Take OrthoFinder's own raw, always-restarts-from-1 sequential numbering for whichever
pool of residual sequences was just clustered (e.g. "OG0000001: seq1 seq2") and turn it
into a final, globally-unique residual group ID: OGR${buildVersion}r${subVersion}_${N},
where N is offset upward by however many OGR numbers earlier runs have already used, so
brand-new residual groups never collide with residual groups any earlier run (full rebuild
or an earlier incremental run) already created.

=head1 Input Parameters

=over 4

=item input

Group file with OrthoFinder's raw "OG<N>: ..." IDs (one line per group)

=item buildVersion

=item subVersion

=item offset

Highest OGR numeric suffix already used by any earlier run (0 for a full rebuild, since
nothing exists yet to collide with)

=item output

=back

=cut

my ($input, $buildVersion, $subVersion, $offset, $output);

&GetOptions("input=s" => \$input,
            "buildVersion=i" => \$buildVersion,
            "subVersion=i" => \$subVersion,
            "offset=i" => \$offset,
            "output=s" => \$output);

$offset ||= 0;

open(my $inFh, '<', $input) || die "Could not open file $input: $!";
open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

while (my $line = <$inFh>) {
    if ($line =~ /^OG(\d+)(:\s.*)$/) {
        my ($number, $rest) = ($1, $2);
        my $width = length($number);
        my $newNumber = $number + $offset;
        my $padded = sprintf("%0${width}d", $newNumber);
        print $outFh "OGR${buildVersion}r${subVersion}_${padded}${rest}\n";
    }
    else {
        # Not a group line (e.g. blank) -- pass through unchanged.
        print $outFh $line;
    }
}

close($inFh);
close($outFh);
