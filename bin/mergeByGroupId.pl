#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Generic merge for any tab-delimited file whose first column is a group ID
(one or many rows per group): drop cached rows for touched groups, then
append the freshly-recomputed rows for those groups. Reused for both group
stats files (one row per group) and intra-group blast value files (many rows
per group) -- filtering is row-wise by column 1 either way.

=head1 Input Parameters

=over 4

=item cached

Previous run's cached file (may not exist, e.g. no cached intraGroupBlastFile.tsv yet).

=item touchedGroups

One group ID per line -- groups whose cached rows should be dropped.

=item fresh

Freshly-recomputed rows for touched groups, same column format.

=item output

Merged output.

=back

=cut

my ($cached, $touchedGroups, $fresh, $output);

&GetOptions("cached=s" => \$cached,
            "touchedGroups=s" => \$touchedGroups,
            "fresh=s" => \$fresh,
            "output=s" => \$output);

open(my $touchedFh, '<', $touchedGroups) || die "Could not open file $touchedGroups: $!";
my %touched;
while (my $line = <$touchedFh>) {
    chomp $line;
    next unless length($line);
    $touched{$line} = 1;
}
close($touchedFh);

open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

if (-e $cached) {
    open(my $cachedFh, '<', $cached) || die "Could not open file $cached: $!";
    while (my $line = <$cachedFh>) {
        chomp $line;
        next unless length($line);

        my ($groupId) = split(/\t/, $line);
        print $outFh "$line\n" unless $touched{$groupId};
    }
    close($cachedFh);
}

open(my $freshFh, '<', $fresh) || die "Could not open file $fresh: $!";
while (my $line = <$freshFh>) {
    print $outFh $line;
}
close($freshFh);

close($outFh);
