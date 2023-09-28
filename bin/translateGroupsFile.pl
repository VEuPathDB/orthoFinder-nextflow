#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groupsFile, $sequenceFile, $singletonsFile, $output);

&GetOptions("groupsFile=s"=> \$groupsFile,
            "sequenceFile=s"=> \$sequenceFile,
            "singletonsFile=s"=> \$singletonsFile,
            "output=s"=> \$output);

open(my $sequence, '<', $sequenceFile) || die "Could not open file $sequenceFile: $!";
open(OUT,">$output");
open(SINGLE,">$singletonsFile");

my %sequenceIDs;

while (my $line = <$sequence>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s(.+)\sgene=/) {
        my ($seqID, $seqName) = ($1, $2);
	$sequenceIDs{$seqName} = $seqID;
    }
    else {
        die "$line Invalid orthogroup file format\n";
    }
}

open(my $group, '<', $groupsFile) || die "Could not open file $groupsFile: $!";

while (my $line = <$group>) {
    chomp $line;
    if ($line =~ /^(OG\d+):\s+(.+)/) {
        my ($group, $sequences) = ($1, $2);
        #$sequences =~ s/\|/\\\|/g;
	my @seqs = split(/\s/, $sequences);
	my $seqSize = scalar @seqs;
	if ($seqSize > 1) {
	    foreach my $seq (@seqs) {
	        $seq = $sequenceIDs{$seq};
	    }
            my $seqString = join(" ", @seqs);
            print OUT "$group: $seqString\n";
	}
	else {
	    my $singleton = $seqs[0];
	    $singleton =~ s/\\\|/\|/g;
	    print SINGLE "$group: ${singleton}\n";
        }
           
    }
    else {
        die "$line Invalid orthogroup file format\n";
    }
}

close SINGLE;
close OUT;
close $sequence;
close $group;
