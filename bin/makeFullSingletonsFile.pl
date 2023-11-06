#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($fileSuffix,$lastGroup,$buildVersion,$outputFile);

&GetOptions("fileSuffix=s"=> \$fileSuffix,
            "lastGroup=s"=> \$lastGroup,
            "buildVersion=s"=> \$buildVersion,
            "outputFile=s"=> \$outputFile);

print "$lastGroup\n";

my $groupIntDigits = 7;
my $groupPrefix = "OG";

my $lastGroupInteger = $lastGroup;
$lastGroupInteger =~ s/^$groupPrefix//;

my @singletonFiles = glob("*.${fileSuffix}");

open(OUT, ">singletonsFull.dat") || die "Could not open full singletons file: $!";

foreach my $file(@singletonFiles) {
    open(my $data, "<$file");
    while (my $line = <$data>) {
        chomp $line;
	# Create New Group
	$lastGroupInteger+=1;
	# Get New Length of Last Group Integer
	my $lengthOfLastGroupInteger = length($lastGroupInteger);
	# Add zeros in front of group to keep consistent formatting
	my $numberOfZerosToAddToStart = $groupIntDigits - $lengthOfLastGroupInteger;
	my $zeroLine = "0" x $numberOfZerosToAddToStart;
	print OUT "${groupPrefix}${buildVersion}_${zeroLine}${lastGroupInteger}\t$line\n";
    }
    close $data;
}

close OUT;
