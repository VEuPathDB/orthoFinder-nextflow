#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($singletons);

&GetOptions("singletons=s"=> \$singletons);

if (-e "singletonsFull.dat") {

    # Get last line from full singletons file so we know what the last group number was
    my $lastLineOfFullFile = `tail -n 1 singletonsFull.dat`;
    chomp $lastLineOfFullFile;
    # Retrieve values from the string
    my ($lastGroup, $lastSeqID) = split(/\t/, $lastLineOfFullFile);
    # Get the last group integer
    my ($lastGroupVersion, $lastGroupInteger) = split(/_/, $lastGroup);
    # Open full singletons file in append mode
    open(OUT, ">>singletonsFull.dat") || die "Could not open full singletons file: $!";
    # Open organism specific singleton file
    open(my $data, '<', $singletons) || die "Could not open file $singletons: $!";
    
    while (my $line = <$data>) {
        chomp $line;
	# Get Group and Seq ID
        my ($group, $seqID) = split(/\t/, $line);
	# Split out integer
	my ($groupVersion, $groupInteger) = split(/\_/, $group);
	# Create New Group
	$lastGroupInteger+=1;
	# Get New Length of Last Group Integer
	my $lengthOfLastGroupInteger = length($lastGroupInteger);
	# Add zeros in front of group to keep consistent formatting
	my $numberOfZerosToAddToStart = 7 - $lengthOfLastGroupInteger;
	my $zeroLine = "0" x $numberOfZerosToAddToStart;
	print OUT "${groupVersion}_${zeroLine}${lastGroupInteger}\t$seqID\n";
    }
    close $data;
}
else {
    # Create full singletons file
    `touch singletonsFull.dat`;
    # First file can just have the same mappings
    `cat $singletons > singletonsFull.dat`;
}


