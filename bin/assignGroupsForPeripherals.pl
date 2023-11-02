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


while (my $line = <$data>) {
    chomp $line;

    my @lineAr = split(/\t/, $line);

    my $qseq = $lineAr[0];
    my $group = $lineAr[1];
    my $evalue = $lineAr[10];

    unless($seqToGroup{$qseq}) {
        $seqToGroup{$qseq}->{evalue} = $evalue;
        $seqToGroup{$qseq}->{group} = $group;
    }

    if($seqToGroup{$qseq}->{evalue} > $evalue) {
        $seqToGroup{$qseq}->{evalue} = $evalue;
        $seqToGroup{$qseq}->{group} = $group;
    }

}

foreach my $seq (keys %seqToGroup) {
    print OUT "$seq\t" . $seqToGroup{$seq}->{group} . "\n";
}
