#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestRepFile, $sequenceFile, $output);

&GetOptions("bestRepFile=s"=> \$bestRepFile,
            "sequenceFile=s"=> \$sequenceFile);

open(my $sequence, '<', $sequenceFile) || die "Could not open file $sequenceFile: $!";

my %sequenceNames;

while (my $line = <$sequence>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s(.+)\sgene=/) {
        my ($seqID, $seqName) = ($1, $2);
	$sequenceNames{$seqID} = $seqName;
    }
    else {
        die "$line Invalid orthogroup file format\n";
    }
}

open(my $best, '<', $bestRepFile) || die "Could not open file $bestRepFile: $!";
my ($sequenceName, $group, $sequenceID);

while (my $line = <$best>) {
    chomp $line;
    if ($line =~ /^(OG\d+):\s+(\d+_\d+)/) {
        ($group, $sequenceID) = ($1, $2);
        $sequenceName = $sequenceNames{$sequenceID};
    }
    else {
        die "$line Invalid best representative file format\n";
    }
}

close $best;

open(BEST,">$bestRepFile") || die "Could not open file $bestRepFile: $!";
print BEST "$group: $sequenceName\n";
close BEST;

close $sequence;

