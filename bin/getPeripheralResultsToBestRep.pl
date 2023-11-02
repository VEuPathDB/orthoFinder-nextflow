#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($similarity,$groups);

&GetOptions("similarity=s"=> \$similarity, # Sorted diamond similarity results
            "groups=s"=> \$groups); # Sorted group assignments

open(my $group, '<', $groups) || die "Could not open file $groups: $!";
open(my $sim, '<', $similarity) || die "Could not open file $similarity: $!";

my %seqToGroup;

while (my $line = <$group>) {
    chomp $line;
    my ($seq,$groupId) = split(/\t/, $line);
    $seqToGroup{$seq} = $groupId;
}
close $group;

my $currentGroupId = "";
while (my $line = <$sim>) {
    chomp $line;
    my ($seq,$groupId, @rest) = split(/\t/, $line);

    next unless($seqToGroup{$seq} eq $groupId);

    if ($groupId eq $currentGroupId) {
        print OUT "$line\n";
        next;
    }

    close OUT if($currentGroupId);
    $currentGroupId = $groupId;
    open(OUT, ">${groupId}_bestRep.tsv") || die "Could not open file ${groupId}_bestRep.tsv: $!";
    print OUT "$line\n";
}

close $sim;
close OUT;
