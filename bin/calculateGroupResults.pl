#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Statistics::Basic::Median;
use Statistics::Descriptive::Weighted;

my ($bestRepResults, $evalueColumn, $isResidual, $outputFile);

&GetOptions("bestRepResults=s"=> \$bestRepResults,
            "evalueColumn=i"=> \$evalueColumn,
            "isResidual"=> \$isResidual,
            "outputFile=s" => \$outputFile);


# Open file that contains pairwise results of sequences involving the groups best rep
open(my $data, '<', $bestRepResults) || die "Could not open file $bestRepResults: $!";

open(OUT, ">$outputFile") or die "Cannot open output file $outputFile for writing: $!";

# Make array to hold evalues
my @evalues;
my $group;

while (my $line = <$data>) {
    chomp $line;

    next unless($line);

    if($line =~ /==> (\S+)_bestRep.tsv <==/) {
        &calculateStatsAndPrint($group, \@evalues) if($group);
        $group = $1;

        if ($isResidual) {
            $group =~ s/OG/OGR/;
        }

        @evalues = ();
        next;
    }

    my @results = split(/\t/, $line);
    push(@evalues,$results[$evalueColumn]);
}

# do the last one
&calculateStatsAndPrint($group, \@evalues) if($group);

close $data;

sub calculateStatsAndPrint {
    my ($group, $evalues) = @_;

    # print the number of similarities (sim+1 should equal the number of sequences in the group)
    # print min,mean,median,....

    my $simCount = scalar(@$evalues);



    if ($simCount >= 1) {
        my $stat = Statistics::Descriptive::Full->new();
        $stat->add_data(@$evalues);

        my $min = $stat->min();
        my $twentyfifth = $stat->percentile(25);
        my $mean = $stat->mean();
        my $median = $stat->percentile(50);
        my $seventyfifth = $stat->percentile(75);
        my $max = $stat->max();
        print OUT "$group\t$min\t$twentyfifth\t$mean\t$median\t$seventyfifth\t$max\n";
    }

}
