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

my $currentGroupId;
my $previousGroupId="first";
my $lineCount;
while (my $line = <$blast>) {
    chomp $line;

    if($line =~ /^(\S+)\t(\S+).+/) {

        my $queryGroupId = $groupBestRepHash{$1};
        my $subjectGroupId = $groupBestRepHash{$2};
	
	if ($queryGroupId) {
	    $currentGroupId = $queryGroupId;
	}
	else {
	    $currentGroupId = $subjectGroupId;
	}

        if ($currentGroupId) {
	    
	    if ($currentGroupId eq $previousGroupId) {
                print OUT "$line\n";
	    }

	    else {

		if ($previousGroupId eq "first") {
		    open(OUT, ">>${currentGroupId}_bestRep.tsv") or die "Cannot open file ${currentGroupId}_bestRep.tsv for writing:$!";
	            print OUT "$line\n";
		}

		else {
		    close OUT;
                    open(OUT, ">>${currentGroupId}_bestRep.tsv") or die "Cannot open file ${currentGroupId}_bestRep.tsv for writing:$!";
	            print OUT "$line\n";
		}
	    }
	    $previousGroupId = $currentGroupId;
	}
    }
    else {
	die "Improper file format of blast Results: $!";
    }

    $lineCount += 1;
    if ($lineCount % 5 == 0) {
	print "Processed $lineCount lines\n";
    }
}

close $blast;
