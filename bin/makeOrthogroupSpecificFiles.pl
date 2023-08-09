#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groupsFile);

&GetOptions("groupsFile=s"=> \$groupsFile);

open(my $data, '<', $groupsFile) || die "Could not open file $groupsFile: $!";

while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^(OG\d+):\s+(.+)/) {
        my ($group, $sequences) = ($1, $2);
        $sequences =~ s/\|/\\\|/g;
	my @seqs = split(/\s/, $sequences);
	my $seqSize = scalar @seqs;
	if ($seqSize > 1) {
            my $seqString = join("|", @seqs);
            system("grep -hE \"${seqString}\" *.txt > ./GroupFiles/OrthoGroup${group}.dat");
	}
	else {
	    my $singleton = $seqs[0];
	    $singleton =~ s/\\\|/\|/g; 
	    system("echo \"${group}:${singleton}\" >> ./GroupFiles/Singletons.dat");
        }
    }
    else {
        die "$line Invalid orthogroup file format\n";
    }
}
