#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($result,$output);

&GetOptions("result=s"=> \$result,
            "output=s"=> \$output);

open(my $data, '<', $result) || die "Could not open file $result: $!";
open(OUT,">$output");

my $lineNumber = 0;
my $currentQSeq;
my $currentSSeq;
my $currentExp;
my $currentMant;
my $mant;
my $exp;
my $lineCount = `wc -l < $result`;
chomp $lineCount;

while (my $line = <$data>) {
    chomp $line;
    my ($qseqid,$qlen,$sseqid,$slen,$qstart,$qend,$sstart,$send,$evalue,$bitscore,$length,$nident,$pident,$positive,$qframe,$qstrand,$gaps,$qseq) = split(/\t/, $line);
    if ($evalue =~ /e/) {
        ($mant, $exp) = split(/e/, $evalue);
    } else {
        $mant = int($evalue);
        $exp = 0;
    }
    if ($lineNumber == $lineCount) {
	if ($currentExp > $exp) {
	    $currentExp = $exp;
	    $currentMant = $mant;
	    $currentSSeq = $sseqid;
	}
	elsif ($currentExp == $exp) {
	    if ($currentMant < $mant) {
		$currentExp = $exp;
	        $currentMant = $mant;
	        $currentSSeq = $sseqid;
	    }
        }
	print OUT "$currentQSeq\t$currentSSeq\n";
    }
    elsif ($lineNumber == 0) {
	$lineNumber+=1;
	$currentQSeq = $qseqid;
	$currentSSeq = $sseqid;
	$currentExp = $exp;
	$currentMant = $mant;
    }
    elsif ($qseqid eq $currentQSeq) {
	$lineNumber+=1;
	if ($currentExp > $exp) {
	    $currentExp = $exp;
	    $currentMant = $mant;
	    $currentSSeq = $sseqid;
	}
	elsif ($currentExp == $exp) {
	    if ($currentMant < $mant) {
		$currentExp = $exp;
	        $currentMant = $mant;
	        $currentSSeq = $sseqid;
	    }
        }
    }
    else {
	$lineNumber+=1;
        print OUT "$currentQSeq\t$currentSSeq\n";
	$currentQSeq = $qseqid;
	$currentSSeq = $sseqid;
	$currentExp = $exp;
	$currentMant = $mant;
    }
    
}	
