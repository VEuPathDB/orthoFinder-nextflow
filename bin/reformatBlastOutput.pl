#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($blastOutput,$sequenceIds,$output);

&GetOptions("blastOutput=s"=> \$blastOutput,
	    "sequenceIds=s"=> \$sequenceIds,
            "output=s"=> \$output);

my %seqIdList = ();
    
open(my $seqs, '<', $sequenceIds) || die "Could not open file $sequenceIds: $!";
while (my $line = <$seqs>) {
    if ($line =~ /^(\d+_\d+):\s(.+)/) {
	$seqIdList{$1} = $2;
    }
    else {
	die "Format is invalid\n";
    }
}

close $seqs;

my ($realQSeqId,$realSSeqId);
open(my $data, '<', $blastOutput) || die "Could not open file $blastOutput: $!";
open(OUT,">$output"); 

while (my $line = <$data>) {
    chomp $line;
    my ($qseqid,$sseqid,$pident,$length,$mismatch,$gapopen,$qstart,$qend,$sstart,$send,$evalue,$bitscore,$qlen,$slen,$nident,$positive,$qframe,$qstrand,$gaps,$qseq) = split(/\t/, $line);
    $realQSeqId = $seqIdList{"$qseqid"};
    $realSSeqId = $seqIdList{"$sseqid"};
    print OUT "$realQSeqId\t$qlen\t$realSSeqId\t$slen\t$qstart\t$qend\t$sstart\t$send\t$evalue\t$bitscore\t$length\t$nident\t$pident\t$positive\t$qframe\t$qstrand\t$gaps\t$qseq\n";
}

close $data;
close OUT;
