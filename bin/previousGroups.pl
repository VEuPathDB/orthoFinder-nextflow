#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

my ($oldGroupsFile,$newGroupsFile,$outputFile);

&GetOptions("oldGroupsFile=s"=> \$oldGroupsFile,
	    "newGroupsFile=s"=> \$newGroupsFile,
	    "outputFile=s"=> \$outputFile);

print "Processing Old\n";

open(my $old, '<', $oldGroupsFile) || die "Could not open file $oldGroupsFile: $!";
my %oldGroupToSeqs;
while (my $line = <$old>) {
    chomp $line;
    if ($line =~ /(\S+):\s?(.*)/) {
        my $groupId = $1;
        my $seqLine = $2;
        my @seqArray = split(/\s/, $seqLine);
	my @fixedSeqArray;
        foreach my $seq (@seqArray) {
            # Record the group assignment for each sequence
            $seq =~ s/.RNA//g;
            $seq =~ s/:RNA//g;
	    $seq =~ s/.mRNA//g;
            $seq =~ s/:mRNA//g;
            $seq =~ s/.pseudo//g;
	    $seq =~ s/:pseudo//g;
            push(@fixedSeqArray, $seq);
        }
	$oldGroupToSeqs{$groupId} = \@fixedSeqArray;
    }
    else {
	die "Improper file format for groups file $oldGroupsFile\nLine is $line\n";
    }
}
close $oldGroupsFile;

print "Processing New\n";

my @newGroups;

open(my $new, '<', $newGroupsFile) || die "Could not open file $newGroupsFile: $!";
my %newSeqToGroup;
while (my $line = <$new>) {
    chomp $line;
    if ($line =~ /(OG\S+):\s(.+)/) {
         my $groupId = $1;
         my $seqLine = $2;
         my @seqArray = split(/\s/, $seqLine);
	 push(@newGroups,$groupId);
         foreach my $seq (@seqArray) {
            # Record the group assignment for each sequence
	     $seq =~ s/.RNA//g;
             $seq =~ s/:RNA//g;
	     $seq =~ s/.mRNA//g;
             $seq =~ s/:mRNA//g;
             $seq =~ s/.pseudo//g;
	     $seq =~ s/:pseudo//g;
            $newSeqToGroup{$seq} = $groupId;
         }
    }
    else {
	die "Improper file format for groups file $newGroupsFile\nLine is $line\n";
    }
}
close $newGroupsFile;

open(OUT, '>', $outputFile) || die "Could not open file $outputFile: $!";

print "Printing old\n";

foreach my $group (keys %oldGroupToSeqs) {
    my @newGroupsArray;
    my @seqArray = @{$oldGroupToSeqs{$group}};
    foreach my $seq (@seqArray) {
        if ($newSeqToGroup{$seq}) {
            push(@newGroupsArray,$newSeqToGroup{$seq});
	}
    }
    # Using a hash to get distinct values
    my %seen;
    my @distinct = grep { !$seen{$_}++ } @newGroupsArray;

    # Print the distinct values
    print OUT "$group\t" . join(", ", @distinct) . "\n";
}

print "Printing new\n";

foreach my $group (@newGroups) {
    print OUT "$group\t$group\n";
}

close OUT;
