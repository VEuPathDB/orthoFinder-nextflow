#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groups,$seqFile,$residuals,$peripherals);

&GetOptions("groups=s"=> \$groups,
	    "seqFile=s"=> \$seqFile,
            "residuals=s"=> \$residuals,
            "peripherals=s"=> \$peripherals);

open(my $data, '<', $seqFile) || die "Could not open file $seqFile: $!";
open(RESI,">$residuals");
open(PERI,">$peripherals");

my $getNextResidualLine;
my $getNextPeripheralLine;

while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^>(\S+)\s.+/) {
	$getNextResidualLine = 0;
	$getNextPeripheralLine = 0;
	my $id = $1;
	my $hasAssignedGroup = `grep "${id}" $groups`;
	if (!$hasAssignedGroup) {
	    print RESI "$line\n";
	    $getNextResidualLine = 1;
	}
	elsif ($hasAssignedGroup) {
	    print PERI "$line\n";
	    $getNextPeripheralLine = 1;
	}
    }
    elsif ($getNextResidualLine == 1) {
	print RESI "$line\n";
    }
    elsif ($getNextPeripheralLine == 1) {
	print PERI "$line\n";
    }
}	
