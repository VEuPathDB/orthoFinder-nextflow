#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($blastFile,$translateFile,$outputFile);

&GetOptions("blastFile=s"=> \$blastFile,
	    "translateFile=s"=> \$translateFile,
            "outputFile=s"=> \$outputFile);

open(SEQ, '<', $translateFile) || die "Could not open file $translateFile: $!";
my %sequenceIdsMap;
while (my $line = <SEQ>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s(\S+)/) {
	my $internal = $1;
	my $actual = $2;
        $sequenceIdsMap{$internal} = $actual;
    }
    else {
        die "Improper sequence id file format: $!";
    }
}
close SEQ;

open(STAT, '<', $blastFile) || die "Could not open file $blastFile: $!";
open(OUT, '>>', $outputFile) || die "Could not open file $outputFile: $!";
my $group;
while (my $line = <STAT>) {
    chomp $line;
    if ($line =~ /^>\s(OG.*)\s</) {
        $group = $1;
	$group =~ s/\.sim//g;
    }
    elsif ($line =~ /^(\S*)\t(\S*)\t(.*)/) {
	my $qseq = $1;
	my $sseq = $2;
	my @values = split(/\t/,$3);
	if (!$qseq) {
            die "No value for qseq for line $line\n";
	}
        elsif ($qseq =~ /^\d+\_\d+/) {
	    if ($sequenceIdsMap{$qseq}) {
                print OUT "$group\t$sequenceIdsMap{$qseq}\t$sequenceIdsMap{$sseq}\t$values[-2]\n";
	    }
	    else {
                die "No value for qseq for line $line\n";
	    }
        }
        else {
            print OUT "$group\t$qseq\t$sseq\t$values[-2]\n";
        }
    }
    else {
	die "Improper file format for line: $line\n";
    }
}
close STAT;
close OUT;
		   
1;
