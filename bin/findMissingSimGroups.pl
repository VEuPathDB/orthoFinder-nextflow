#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

For an explicit, arbitrary list of group IDs (not necessarily a contiguous
numeric range -- unlike checkForMissingGroups.pl, which assumes one), report
which ones have no "<groupID>.sim" file, i.e. singleton groups with no
pairwise similarity data to pick a best representative from.

=head1 Input Parameters

=over 4

=item groupList

One group ID per line.

=item simDir

Directory expected to contain "<groupID>.sim" for each group with pairwise data.

=item output

One group ID per line, for every group missing a .sim file.

=back

=cut

my ($groupList, $simDir, $output);

&GetOptions("groupList=s" => \$groupList,
            "simDir=s" => \$simDir,
            "output=s" => \$output);

open(my $listFh, '<', $groupList) || die "Could not open file $groupList: $!";
open(my $outFh, '>', $output) || die "Could not open file $output for writing: $!";

while (my $line = <$listFh>) {
    chomp $line;
    next unless length($line);

    # -s (exists AND non-empty): a singleton group's self-diamond run still
    # produces a (0-byte, --no-self-hits) .sim file, not a missing one.
    print $outFh "$line\n" unless -s "$simDir/$line.sim";
}

close($listFh);
close($outFh);
