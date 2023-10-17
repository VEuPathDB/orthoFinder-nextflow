#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groupFile,$buildVersion);

&GetOptions("groupFile=s"=> \$groupFile,
            "buildVersion=i"=> \$buildVersion);

open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";
open(OUT, '>reformattedGroups.txt') || die "Could not open file reformattedGroups.txt: $!";

my $numberOfOrganisms;

while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^HOG/) {
        my @headerArray = split(/\t/, $line);
	my $numberOfColumns = scalar @headerArray;
	$numberOfOrganisms = $numberOfColumns - 3;
    }
    else {
	$line =~ s/,//g;
	my @valuesArray = split(/\t/, $line);
	my @allSequences;
	foreach my $i (1..$numberOfOrganisms) {
	    my $index = 2 + $i;
	    if ($valuesArray[$index]) {
                push(@allSequences,$valuesArray[$index]);
	    }
	}
	my $group = $valuesArray[1];
	$group =~ s/OG/OG${buildVersion}_/;
        print OUT "$group: @allSequences\n";
    }
}

close $data;
close OUT
