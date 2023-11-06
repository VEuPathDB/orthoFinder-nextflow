#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($singletons,$groups,$buildVersion);

&GetOptions("singletons=s"=> \$singletons,
            "groups=s"=> \$groups,
            "buildVersion=s"=> \$buildVersion);

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
	# Create New Group
	$lastGroupInteger+=1;
	# Get New Length of Last Group Integer
	my $lengthOfLastGroupInteger = length($lastGroupInteger);
	# Add zeros in front of group to keep consistent formatting
	my $numberOfZerosToAddToStart = 7 - $lengthOfLastGroupInteger;
	my $zeroLine = "0" x $numberOfZerosToAddToStart;
	print OUT "${lastGroupVersion}_${zeroLine}${lastGroupInteger}\t$line\n";
    }
    close $data;
    close OUT;
}
else {
    open(my $group, '<', $groups) || die "Could not open file $groups: $!";
    my $lastGroupID;
    while (my $line = <$group>) {
        chomp $line;
	# Get Values
        my @values = split(/\t/, $line);
	# Split out groupID
	my $groupID = $values[1];
	$groupID =~ s/OG//g;
	$lastGroupID = $groupID;
    }
    # Create full singletons file
    open(OUT, ">singletonsFull.dat") || die "Could not open full singletons file: $!";
    open(my $data, '<', $singletons) || die "Could not open file $singletons: $!";
    while (my $line = <$data>) {
        chomp $line;
	$lastGroupID+=1;
	# Get New Length of Last Group Integer
	my $lengthOfLastGroupInteger = length($lastGroupID);
	# Add zeros in front of group to keep consistent formatting
	my $numberOfZerosToAddToStart = 7 - $lengthOfLastGroupInteger;
	my $zeroLine = "0" x $numberOfZerosToAddToStart;
	my $groupWithBuild = "OG${buildVersion}_${zeroLine}${lastGroupID}";
	print OUT "$groupWithBuild\t$line\n";
    }
    close OUT;
}


