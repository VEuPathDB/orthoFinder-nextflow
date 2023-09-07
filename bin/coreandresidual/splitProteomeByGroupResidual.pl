#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groups,$proteome);

&GetOptions("groups=s"=> \$groups,
	    "proteome=s"=> \$proteome);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";

while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^(OG\S+)\s+(\S.+)/) {
	my $groupId = $1;
	my $sequences = $2;
	$sequences =~ s/\s\s\s\s\s/\t/g;
	$sequences =~ s/\t/,/g;
	$sequences =~ s/\s//g;
        my @seqs = split(/,/, $sequences);
        `touch ${groupId}.temp`;
        `touch ${groupId}.fasta`;
	open(TEMP,">${groupId}.temp");
	foreach my $seq (@seqs) {
	    print TEMP "$seq\n";
	}
	`seqtk subseq ${proteome} ${groupId}.temp > ${groupId}.fasta`;
	close TEMP;
	`rm ${groupId}.temp`
    }
    elsif ($line =~ /^Orthogroup/) {
	next;
    }
    else {
	die "Improper format of groups file $groups";
    }
}	
