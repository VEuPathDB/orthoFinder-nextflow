#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Statistics::Basic::Median;
use Statistics::Descriptive::Weighted;

my ($bestRepResults, $evalueColumn, $isResidual, $outputFile);

&GetOptions("bestRepResults=s"=> \$bestRepResults,
            "evalueColumn=i"=> \$evalueColumn,
            "outputFile=s" => \$outputFile);

# Open file that contains pairwise results of sequences involving the groups best rep
open(my $data, '<', $bestRepResults) || die "Could not open file $bestRepResults: $!";

open(OUT, ">$outputFile") or die "Cannot open output file $outputFile for writing: $!";

# Make array to hold evalues
my @evalues;
my $group;
my $previousGroup = "first";

# For each blast result to group's best representative...
while (my $line = <$data>) {
    chomp $line;

    next unless($line);

    # If we have moved on to another group. Retrieve new group id and calculate stats for last group.
    if($line =~ /(^OG\S+)\t(.+)/) {

	$group = $1;
        my $stats = $2;
	
	if ($group eq $previousGroup || $previousGroup eq "first") {
	    
            # If still previous group, retrieve blast results.
            my @results = split(/\t/, $stats);

            # Capture evalue.
            my $evalue = $results[$evalueColumn];

            # An unmapped value was returned.
            $evalue = 1 if ($evalue == -1);
	    
	    # Add evalue to array.
            push(@evalues,$evalue);

	    $previousGroup = $group;

	}

	else {

	    # Calculate stats of last group
            &calculateStatsAndPrint($previousGroup, \@evalues);

            # Clear evalue hash as we are starting a new group.
            @evalues = ();

	    # Retrieve blast results.
            my @results = split(/\t/, $stats);

            # Capture evalue.
            my $evalue = $results[$evalueColumn];

            # An unmapped value was returned.
            $evalue = 1 if ($evalue == -1);
	    
	    # Add evalue to array.
            push(@evalues,$evalue);

	    $previousGroup = $group;

	}   

    }

    else {

	die "Improper file format for $bestRepResults : $!";

    }
    
}

# Calculate stats for the last group.
&calculateStatsAndPrint($previousGroup, \@evalues);

close $data;

=pod

=head1 Subroutines

=over 4

=item calculateStatsAndPrint()

The process takes the group id and the evalues retrieve from the group pairwise results and calculates the group statistics.

=back

=cut

sub calculateStatsAndPrint {
    my ($group, $evalues) = @_;

    # Add R as there are residual
    $group =~ s/OG/OGR/;
    
    # Count number of similarities.
    my $simCount = scalar(@$evalues);

    # If we have a similarity.
    if ($simCount >= 1) {
	
	# Create stats object.
        my $stat = Statistics::Descriptive::Full->new();
	
	# Add evalues.
        $stat->add_data(@$evalues);

	# Calculate values and print.
        my $min = $stat->min();
        my $twentyfifth = $stat->percentile(25);
        my $mean = $stat->mean();
        my $median = $stat->percentile(50);
        my $seventyfifth = $stat->percentile(75);
        my $max = $stat->max();
        print OUT "$group\t$min\t$twentyfifth\t$median\t$seventyfifth\t$max\t$simCount\n";
    }

}

close OUT;
1;
