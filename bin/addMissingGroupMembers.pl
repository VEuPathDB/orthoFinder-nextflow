#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($missingGroups,$groupMapping);

&GetOptions("groupMapping=s"=> \$groupMapping,
            "missingGroups=s"=> \$missingGroups);

open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";

my %missingHash;

while (my $line = <$missing>) {
    chomp $line;
    # Save full missing group ID for later
    $missingHash{$line} = 1;
}
close $missing;

# Open group mapping
open(my $group, '<', $groupMapping) || die "Could not open file $groupMapping: $!";

# For each mapping
while (my $line = <$group>) {
    chomp $line;
    if ($line =~ /^(\S+_\S+):\s(.*)/) {	
        if ($missingHash{$1}) {
            my @seqs = split(/\s/,$2);
            print "$1\t$seqs[0]\n";
        }
    }
    else {
        die "Improper file format: $line\n";
    }
}

close $group;
