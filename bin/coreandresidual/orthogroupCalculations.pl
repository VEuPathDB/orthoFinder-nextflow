#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use List::Util qw( reduce );

my ($groupFile);

&GetOptions("groupFile=s"=> \$groupFile);


open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";

my $group = $groupFile;
$group =~ s/OrthoGroup//g;
$group =~ s/\.dat//g;

my %values;

while (my $line = <$data>) {
    chomp $line;
    if ($line =~  /^([^\t]+)\t(?:[^\t]+\t){9}([^\t]+)\t(?:[^\t]+\t){10}\w+$/) {
        my ($qseq, $evalue) = ($1, $2);
	print "$qseq\t$evalue\n";
	if (exists($values{$qseq}[0])) {
	    	    push( @{ $values{$qseq} }, $evalue); 
	}
	else {
            @values{$qseq} = [];
	    push( @{ $values{$qseq} }, $evalue); 
	}
    }
    else {
	die;
    }
}

my %seqSum;

foreach my $key (keys %values) {
    my @scores = @{$values{$key}};
    my $sum = 0;
    for my $each (@scores) {
        $sum += $each;
    }
    $seqSum{$key} = $sum;
}

my $bestRepresentative = reduce { $seqSum{$a} < $seqSum{$b} ? $a : $b } keys %seqSum;

system("echo \"${group}:${bestRepresentative}\" > ${group}.final");
