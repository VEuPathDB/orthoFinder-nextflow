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
    my ($qseqid,$qlen,$sseqid,$slen,$qstart,$qend,$sstart,$send,$evalue,$bitscore,$length,$nident,$pident,$positive,$qframe,$qstrand,$gaps,$qcovhsp,$scovhsp,$qseq) = split(/\t/, $line);
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
print OUT "$currentQSeqId" . ": " . $outputString . "\n";

close OUT;
close $data;