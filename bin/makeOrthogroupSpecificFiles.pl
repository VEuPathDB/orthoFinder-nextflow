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
        my $seqString = join("|", @seqs);
        system("grep -hE \"${seqString}\" *.txt > OrthoGroup${group}.dat");
    }
    else {
        die "$line Invalid orthogroup file format\n";
    }
}
