#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groups,$proteome);

&GetOptions("groups=s"=> \$groups,
	    "proteome=s"=> \$proteome);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";
open(OUT,">fastaWithGroups.fasta")  || die "Could not open file fastaWithGroups.fasta: $!";

print "Creating sequence group hash\n";
system("date");

# Make hash to store sequence group assignments
my %seqToGroup;

# For each line in groups file
while (my $line = <$data>) {
    chomp $line;
    my ($groupId,$allSequencesString) = split(/:\s/, $line);
    my (@allSequences) = split(/\s/, $allSequencesString);
    foreach my $seq (@allSequences) {
    # Record the group assignment for each sequence
    $seqToGroup{$seq} = $groupId;
    }
}
close $data;

print "Creating fasta with groups\n";
system("date");

open(my $pro, '<', $proteome) || die "Could not open file $proteome: $!";

while (my $line = <$pro>) {
    chomp $line;
    if ($line =~ /^>(\S*)(.*)/) {
        my $seqId = $1;
        my $header = $2;
        if ($seqToGroup{$seqId}) {
            print OUT ">$seqId\t$seqToGroup{$seqId}\t$header\n";
        }
        else {
            my $fixedId = $seqId;
            $fixedId =~ s/:RNA/_RNA/g;
            $fixedId =~ s/:mRNA/_mRNA/g;
            if ($seqToGroup{$fixedId}) {
                print OUT ">$seqId\t$seqToGroup{$fixedId}\t$header\n";
            }
            else {
                die "$fixedId not found in group assignments. seqId is $seqId\n";
            }
        }
    }
    else {
        print OUT "$line\n";
    }
}
print "Done";
system("date");

close $pro;
close OUT;
