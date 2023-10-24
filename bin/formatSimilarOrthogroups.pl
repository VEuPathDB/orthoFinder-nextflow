#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$output);

&GetOptions("input=s"=> \$input,
            "output=s"=> \$output);

open(my $data, '<', $input) || die "Could not open file $input: $!";
open(OUT,">$output");

my $currentQSeqId = "";
my @sequenceIdEvalue;

while (my $line = <$data>) {
    chomp $line;
    my ($qseqid,$sseqid,$pident,$length,$mismatch,$gapopen,$qstart,$qend,$sstart,$send,$evalue,$bitscore) = split(/\t/, $line);
    if ($qseqid eq $currentQSeqId) {
        push(@sequenceIdEvalue, "$sseqid $evalue");
    }
    else {
        my $numberOfHits = scalar @sequenceIdEvalue;
	if ($numberOfHits > 0) {
	    my $outputString = join(',',@sequenceIdEvalue);
	    print OUT "$currentQSeqId" . ": " . $outputString . "\n";
	}
	$currentQSeqId = $qseqid;
	@sequenceIdEvalue = ();
        push(@sequenceIdEvalue, "$sseqid $evalue");
    }
}

my $outputString = join(',',@sequenceIdEvalue);
if ($currentQSeqId ne "") {
    print OUT "$currentQSeqId" . ": " . $outputString . "\n";
}

close OUT;
close $data;
