#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Statistics::Basic::Median;
use Statistics::Descriptive::Weighted;

=pod

=head1 Description

Calculate group statistics from input of pairwise blast results, for a group, between sequences in the group and the best representative of the same group.

=head1 Input Parameters

=over 4

=item bestRepResults

The group specific pairwise results file.

=back

=over 4

=item evalueColumn

The (0th indexed) column number that contains the e-value.

=back

=over 4

=item isResidual

A boolean indicating if these are residual or core groups (if residual, OG7_0000000 becomes OGR7_0000000).

=back

=over 4

=item outputFile

The path to where the group stats will be written.

=back

=cut

my ($evalueColumn, $inputDir, $outputFile);

&GetOptions("inputDir=s"=> \$inputDir,
            "outputFile=s" => \$outputFile);

open(OUT, ">$outputFile") or die "Cannot open output file $outputFile for writing: $!";

# Creating array of group similarity files.                                                                                                                                                                
my @files = <$inputDir/*.mash>;
# For every mash file.                                                                                                                                                                        
foreach my $file (@files) {
    # Make array to hold percents
    my @percentArray;
    my $group;
    # Open file that contains mash results to best rep
    open(my $data, '<', $file) || die "Could not open file $file: $!";
    $group = $file;
    $group =~ s/${inputDir}\///g;
    $group =~ s/\.mash//g;  
    # For each mash result to group's best representative...
    while (my $line = <$data>) {
        chomp $line;
        next unless($line); 

        my @results = split(/\t/, $line);

        my $fraction = $results[4];

        my ($numerator,$denominator) = split(/\//, $fraction);

        my $percent = $numerator / $denominator;
    
        # Add evalue to array.
        push(@percentArray,$percent);
    }
    &calculateStatsAndPrint($group, \@percentArray);
    close $data;
}

=pod

=head1 Subroutines

=over 4

=item calculateStatsAndPrint()

The process takes the group id and the percent shared kmers retrieved from the group pairwise results and calculates the group statistics.

=back

=cut

sub calculateStatsAndPrint {
    my ($group, $percents) = @_;

    # Count number of similarities.
    my $simCount = scalar(@$percents);

    # If we have a similarity.
    if ($simCount >= 1) {
	
	# Create stats object.
        my $stat = Statistics::Descriptive::Full->new();
	
	# Add percents.
        $stat->add_data(@$percents);

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
