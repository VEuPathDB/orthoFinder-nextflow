#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Statistics::Basic::Median;
use Statistics::Descriptive::Weighted;    

my ($bestRepResults,$evalueColumn);

&GetOptions("bestRepResults=s"=> \$bestRepResults,
            "evalueColumn=i"=> \$evalueColumn);

# Open file that contains pairwise results of sequences involving the groups best rep
open(my $data, '<', $bestRepResults) || die "Could not open file $bestRepResults: $!";

# Make array to hold evalues
my @evalues;
while (my $line = <$data>) {
    chomp $line;
    my @results = split(/\t/, $line);
    push(@evalues,$results[$evalueColumn]);
}

close $data;

my $finalFileName = $bestRepResults;
$finalFileName =~ s/bestRep/final/;
open(OUT, ">${finalFileName}") or die "Cannot open output file $finalFileName for writing: $!";

if (scalar(@evalues) >= 1) {
    my $stat = Statistics::Descriptive::Full->new(); 
    $stat->add_data(@evalues);

    my $min = $stat->min();
    my $twentyfifth = $stat->percentile(25);
    my $mean = $stat->mean();
    my $seventyfifth = $stat->percentile(75);
    my $max = $stat->max();
    print OUT "$min\t$twentyfifth\t$mean\t$seventyfifth\t$max\n";

}
else {
    print OUT "Singleton\n";
}
