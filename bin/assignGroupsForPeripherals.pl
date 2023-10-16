#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($result,$output);

&GetOptions("result=s"=> \$result, # Sorted diamond similarity results
            "output=s"=> \$output);

open(my $data, '<', $result) || die "Could not open file $result: $!";
open(OUT,">$output");

my %seqToGroup;
my %seqToEvalue;

while (my $line = <$data>) {
    chomp $line;
    my ($qseq,$groupId,$evalue) = split(/\t/, $line);
    if ($seqToGroup{$qseq}) {
        if ($seqToEvalue{$qseq} > $evalue) {
            $seqToGroup{$qseq} = $groupId;
	    $seqToEvalue{$qseq} = $evalue;
	}
    }
    else {
        $seqToGroup{$qseq} = $groupId;
	$seqToEvalue{$qseq} = $evalue;
    }
}

foreach my $seq (keys %seqToGroup) {
    print OUT "$seq\t$seqToGroup{$seq}\n";
}
