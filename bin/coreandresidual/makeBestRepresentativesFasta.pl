#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestReps,$fasta);

&GetOptions("bestReps=s"=> \$bestReps,
            "fasta=s" => \$fasta);

open(my $data, '<', $bestReps) || die "Could not open file $bestReps: $!";
open(OUT,">./bestReps.fasta");

while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^(OG\d+):(.+)/) {
        my ($group, $repseq) = ($1, $2);
	my $searchSeq = $repseq;
        $searchSeq =~ s/\s.+//g;
	$searchSeq =~ s/\|/\\\|/g;
        my $seq = `samtools faidx $fasta $searchSeq`;
        $seq = $seq =~ s/>.+\n//gr;
	print OUT ">${group} $repseq\n$seq";
    }
    else {
	next;
    }
}
close OUT;
