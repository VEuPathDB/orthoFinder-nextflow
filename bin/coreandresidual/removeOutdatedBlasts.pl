#!/usr/bin/perl

use strict;
use warnings;

use File::Basename;

# Input species ID file
my $outdatedFile = $ARGV[0];
my $previousBlastDir  = $ARGV[1];

my @files = map { basename $_ } glob "$previousBlastDir/*";


# Open Outdated file
open my $fh_outdated, '<', $outdatedFile or die "Cannot open $outdatedFile: $!";

while (my $orgAbbrev = <$fh_outdated>) {

    foreach my $file(@files) {
        if($file =~ /^${orgAbbrev}_/ || $file =~ /_${orgAbbrev}$/) {

            # JB: if this doesn't work, use the system command
            unlink "$previousBlastDir/$file";
        }
    }
}
close $fh_outdated;

1;
