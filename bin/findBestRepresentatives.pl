#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

my ($groupFile);

&GetOptions("groupFile=s"=> \$groupFile); # Pairwise blast results per group

my $QSEQ_COLUMN = 0;
my $EVALUE_COLUMN = 10;

open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";

my $group;

my %values;

while (my $line = <$data>) {
    chomp $line;
    next unless($line);

    if($line =~ /==> (\S+).sim <==/) {
        &calculateAverageAndPrintGroup($group, \%values) if($group);
        $group = $1;
        %values = ();
        next;
    }

    # Get array of pairwise blast results
    my @lineAr = split(/\t/, $line);

    # Retrieve query sequence
    my $qseq = $lineAr[$QSEQ_COLUMN];

    # Retrieve evalue
    my $evalue = $lineAr[$EVALUE_COLUMN];

    $values{$qseq}->{sum} += $evalue;
    $values{$qseq}->{total}++;
}

# make sure to do the last group here
&calculateAverageAndPrintGroup($group, \%values) if($group);

1;


sub calculateAverageAndPrintGroup {
    my ($group, $values) = @_;

    my $minValue = 1000000000;

    my $bestRepresentative;

    # For every query sequence
    foreach my $qseq (keys %values) {
        my $avg = $values{$qseq}->{sum} / $values{$qseq}->{total} ;
        if($avg <= $minValue) {
            $bestRepresentative = $qseq;
            $minValue = $avg;
        }
    }


    print "${group}\t${bestRepresentative}\n";
}
