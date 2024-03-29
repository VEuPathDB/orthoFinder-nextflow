#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $outdatedFile = $ARGV[0];
my $fullProteome = $ARGV[1];
my $newProteome = $ARGV[2];

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

open my $fh_full, '<', $fullProteome or die "Cannot open $fullProteome: $!";
open(OUT,">$newProteome");
my $printSeqs = 0;
while (my $line = <$fh_full>) {
    chomp $line;
    if ($line =~ /^>(\S+)\s.+/) {
	$printSeqs = 0;
        my $headerLine = ($1);
	$headerLine =~ s/\|\S+//g;	
	if ( grep( /^$headerLine/, @outdated ) ) {
            $printSeqs = 1;
	    print OUT "$line\n";
        }
    }
    elsif ($printSeqs == 1) {
	print OUT "$line\n";
    }
}
close $fh_full;
close OUT;
