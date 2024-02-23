#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestRepsFasta,$outputDir);

&GetOptions("bestRepsFasta=s"=> \$bestRepsFasta,
	    "outputDir=s"=> \$outputDir);

open(my $reps, '<', $bestRepsFasta) || die "Could not open file $bestRepsFasta: $!";

my $currentGroupId;
while (my $line = <$reps>) {
    chomp $line;

    if ($line =~ /^>(.*)/) {
	my $groupId = $1;
	
	close OUT if ($currentGroupId);
	open(OUT,">$outputDir/${groupId}.fasta")  || die "Could not open file ${outputDir}/${groupId}.fasta: $!";
	print OUT "$line\n";
	$currentGroupId eq $groupId;
	
    }
    else {
        print OUT "$line\n";
    }
}	
close OUT;
close $reps;
