#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Statistics::Basic::Median;
use Statistics::Descriptive::Weighted;

my ($inputDir, $bestRepFile, $groupsFile, $missingGroups, $outputFile);

&GetOptions("inputDir=s"=> \$inputDir,
	    "bestRepFile=s"=> \$bestRepFile,
    	    "groupsFile=s"=> \$groupsFile,
   	    "missingGroups=s"=> \$missingGroups,
            "outputFile=s" => \$outputFile);

open(OUT, ">$outputFile") or die "Cannot open output file $outputFile for writing: $!";

open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";
my %missingGroupsHash;
while (my $line = <$missing>) {
    chomp $line;
    if ($line =~ /(OG\S+)/) {
	$missingGroupsHash{$1} = 1;
    }
    else {
	die "Improper file format: $line";
    }
}
close $missing;

open(my $coreGroups, '<', $groupsFile) || die "Could not open file $groupsFile: $!";
my %groupToGroupSize;
while (my $line = <$coreGroups>) {
    chomp $line;
    my $group;
    my @sequenceArray;
    if ($line =~ /(OG\S+):\s(.*)/) {
        $group = $1;
	@sequenceArray = split(/\s/, $2);
	my $groupSize = scalar(@sequenceArray);
	$groupToGroupSize{$group} = $groupSize;
    }
    else {
	die "Improper file format: $line";
    }
}
close $coreGroups;

open(my $best, '<', $bestRepFile) || die "Could not open file $bestRepFile: $!";
my %bestRepToGroup;
while (my $line = <$best>) {
    chomp $line;
    if ($line =~ /(OG\S+)\t(\S+)/) {
        $bestRepToGroup{$2} = $1;
    }
    else {
	die "Improper file format: $line";
    }
}
close $best;


foreach my $bestRep (keys %bestRepToGroup) {
    my $group = $bestRepToGroup{$bestRep};
    my $groupSize = $groupToGroupSize{$group};
    my $diamondFile = "$inputDir/$group" . ".sim";
    my @evalueArray;
    if (!$missingGroupsHash{$group}) {
        open(my $data, '<', $diamondFile) || die "Could not open file $diamondFile: $!";
        while (my $line = <$data>) {
            if ($line =~ /(\S+)\t(\S+)\t\S+\t\S+\t\S+\t\S+\t\S+\t\S+\t\S+\t\S+\t(\S+)\t\S+/) {
		my $query = $1;
	        my $target = $2;
	        my $evalue = $3;
		if($query eq $target) {
		    next;
		}
		if ($target eq $bestRep) {
		    if ($evalue < 1.0e-200) {
                        push(@evalueArray, '1.0e-200');
	            }
		    else {
                        push(@evalueArray, $evalue);
		    }
	        }
	    }
	    else {
                die "Improper file format: $line";
	    }
	}
        my $evalueCount = scalar(@evalueArray);
        my $nonSignificantResultCount = $groupSize - $evalueCount;
        # Adding rows for non significant diamond results
        foreach my $i (1..$nonSignificantResultCount) {
            push(@evalueArray, '1.0e-5');    
        }
        &calculateStatsAndPrint($group, \@evalueArray);
        close $data;
    }
    else {
        print OUT "$group\t0\t0\t0\t0\t0\t1\n";
    }
}


=pod

=head1 Subroutines

=over 4

=item calculateStatsAndPrint()

The process takes the group id, group size and the evalue scores to the group best rep from the group pairwise results and calculates the group statistics.

=back

=cut

sub calculateStatsAndPrint {
    my ($group, $evalues) = @_;

    # Count number of similarities.
    my $simCount = scalar(@$evalues);

    # If we have a similarity.
    if ($simCount >= 1) {
	
	# Create stats object.
        my $stat = Statistics::Descriptive::Full->new();
	
	# Add percents.
        $stat->add_data(@$evalues);

	# Calculate values and print.
        my $min = $stat->min();
        my $twentyfifth = $stat->quantile(1);
        my $median = $stat->median();
        my $seventyfifth = $stat->quantile(3);
        my $max = $stat->max();
        print OUT "$group\t$min\t$twentyfifth\t$median\t$seventyfifth\t$max\t$simCount\n";
    }

}

close OUT;
1;
