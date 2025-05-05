#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($oldGroupsFile, $newGroupsFile, $outputFile);

GetOptions(
    "oldGroupsFile=s" => \$oldGroupsFile,
    "newGroupsFile=s" => \$newGroupsFile,
    "outputFile=s"    => \$outputFile
) or die "Error in command line arguments\n";

# Subroutine to clean and lowercase sequence identifiers
sub clean_seq {
    my ($seq) = @_;
    $seq =~ s/\.?(RNA|mRNA|pseudo)//g;
    $seq =~ s/:?(RNA|mRNA|pseudo)//g;
    $seq =~ s/-old//g;
    return lc($seq);
}

print "Processing Old Groups\n";
open(my $old, '<', $oldGroupsFile) or die "Could not open file $oldGroupsFile: $!";

my %oldGroupToSeqs;
my %oldGroupSeqCount;
my %seqToOldGroups;

while (my $line = <$old>) {
    chomp $line;
    if ($line =~ /(\S+):\s?(.*)/) {
        my ($groupId, $seqLine) = ($1, $2);
        my @seqArray = split(/\s+/, $seqLine);
        my @cleanedSeqs;

        foreach my $seq (@seqArray) {
            my $cleaned = clean_seq($seq);
            push @cleanedSeqs, $cleaned;
            push @{ $seqToOldGroups{$cleaned} }, $groupId;  # Reverse index
        }

        $oldGroupToSeqs{$groupId} = \@cleanedSeqs;
        $oldGroupSeqCount{$groupId} = scalar @cleanedSeqs;
    } else {
        die "Improper format in $oldGroupsFile\nLine: $line\n";
    }
}
close($old);

print "Processing New Groups\n";
open(my $new, '<', $newGroupsFile) or die "Could not open file $newGroupsFile: $!";

my %newGroupToSeqs;
while (my $line = <$new>) {
    chomp $line;
    if ($line =~ /(\S+):\s?(.*)/) {
        my ($groupId, $seqLine) = ($1, $2);
        my @seqArray = split(/\s+/, $seqLine);
        my @cleanedSeqs = map { clean_seq($_) } @seqArray;
        $newGroupToSeqs{$groupId} = \@cleanedSeqs;
    } else {
        die "Improper format in $newGroupsFile\nLine: $line\n";
    }
}
close($new);

print "Generating Output\n";
open(my $out, '>', $outputFile) or die "Could not open file $outputFile: $!";

my $totalGroups = scalar keys %newGroupToSeqs;
my $progress_interval = int($totalGroups / 100) || 1;
my $processedCount = 0;

foreach my $newGroup (keys %newGroupToSeqs) {
    my @seqs = @{ $newGroupToSeqs{$newGroup} };
    my %hitCount;

    my $newGroupSeqCount = scalar @seqs;
    
    foreach my $seq (@seqs) {
        next unless exists $seqToOldGroups{$seq};
        foreach my $oldGroup (@{ $seqToOldGroups{$seq} }) {
            $hitCount{$oldGroup}++;
        }
    }

    my $groupString = join " ",
        map { "$_:$hitCount{$_}/$oldGroupSeqCount{$_}" }
        sort keys %hitCount;

    print $out "$newGroup\t$newGroup:$newGroupSeqCount/$newGroupSeqCount $groupString\n";

    $processedCount++;
    if ($processedCount % $progress_interval == 0) {
        my $percent = int(($processedCount / $totalGroups) * 100);
        print "Processed $percent%\n";
    }
}

close($out);

print "Done. Output written to $outputFile\n";
