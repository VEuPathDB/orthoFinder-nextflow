#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $fullProteome = $ARGV[0];
my $newProteome = $ARGV[1];

open my $fh_full, '<', $fullProteome or die "Cannot open $fullProteome: $!";
open(OUT,">$newProteome");
my $headerCount = 0;
while (my $line = <$fh_full>) {
    chomp $line;
    if ($line =~ /^(>\S+)\s.+/) {
	$headerCount += 1;
        my $headerLine = ($1);
        print OUT "$headerLine\n";
    }
    else {
	print OUT "$line\n";
    }
}
close $fh_full;
close OUT;

if ($headerCount < 2) {
    `rm $newProteome`;
    print "$newProteome only contains a single sequence\n";
}
