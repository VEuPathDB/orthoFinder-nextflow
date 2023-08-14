#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $outdatedFile = $ARGV[0];

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

# Read files in the previous blasts directory
opendir(my $dh, "/previousBlasts/") or die "Cannot open directory /previousBlasts/: $!";
while (my $file = readdir($dh)) {
    if (grep( /^$file$/, @outdated)) {
        system("rm /previousBlasts/${file}");
    }
}
closedir($dh);
