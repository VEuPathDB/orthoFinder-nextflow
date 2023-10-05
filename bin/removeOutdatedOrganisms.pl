#!/usr/bin/perl

use strict;
use warnings;

my $outdatedFile = $ARGV[0];
my $peripheralCache = $ARGV[1];

# Open Outdated file
open my $fh_outdated, '<', $outdatedFile or die "Cannot open $outdatedFile: $!";
my @outdated;
while (my $line = <$fh_outdated>) {
    chomp $line;
    if ($line =~ /^(.+)/) {
        my ($outdatedSpecies) = ($1);
        push(@outdated, $outdatedSpecies);
    }
}
close $fh_outdated;

foreach my $update (@outdated) {
    if (-e "$peripheralCache/${update}.fasta.out") {
        system("rm $peripheralCache/${update}.fasta.out");
	print "Removed ${update}.fasta.out from cache";
    }
}
