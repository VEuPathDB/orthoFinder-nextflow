#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($bestReps, $singletons,$blastResults);

&GetOptions("bestReps=s"=> \$bestReps,
            "singletons=s"=> \$singletons,
            "blastResults=s"=> \$blastResults);

# Open file that contains ids of best reps and their group.
open(my $data, '<', $bestReps) || die "Could not open file $bestReps: $!
";

# Open singleton file so we can identify singletons.
open(my $single, '<', $singletons) || die "Could not open file $singletons: $!";

# Open blastResults
open(my $blast, '<', $blastResults) || die "Could not open file $blastResults: $!";

# Create a group file for all singletons, as they have no diamond results
while (my $line = <$single>) {
    chomp $line;
    my ($group, $seqID) = split(/\t/, $line);
    open(OUT, ">${group}_bestRep.tsv") or die "Cannot open file ${group}_bestRep.tsv for writing:$!";
    close OUT;
}

my %groupBestRepHash;
while (my $line = <$data>) {
    chomp $line;
    # Get the group and sequence id
    my ($group, $seqID) = split(/\t/, $line);
    $groupBestRepHash{$seqID} = $group;
}

close $data;

open(OUT, ">>bestRep.tsv") or die "Cannot open file bestRep.tsv for writing:$!";

my $lineCount;
while (my $line = <$blast>) {
    chomp $line;

    if($line =~ /^(\S+)\t(\S+).+/) {

	my $groupId;
        my $queryGroupId = $groupBestRepHash{$1};
        my $subjectGroupId = $groupBestRepHash{$2};
	
	if ($queryGroupId) {
	    $groupId = $queryGroupId;
	}
	else {
	    $groupId = $subjectGroupId;
	}

        if ($groupId) {
	    
            print OUT "$groupId\t$line\n";

	}
    }
    else {
	die "Improper file format of blast Results: $!";
    }

    $lineCount += 1;
    if ($lineCount % 5000 == 0) {
	print "Processed $lineCount lines\n";
    }
}

close $blast;
