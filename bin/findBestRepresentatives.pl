#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use List::Util qw( reduce );

use Data::Dumper;

my ($groupFile, $outputFile);

&GetOptions("groupFile=s"=> \$groupFile,
    "output_file=s" => \$outputFile);

my $QSEQ_COLUMN = 1;
#TODO this doesn't seem like an e value
#TODO check this.  Probably best to use the param/config string to ensure this is the right field
my $EVALUE_COLUMN = 10;

open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";

my $group = $groupFile;
$group =~ s/\.sim$//;

my %values;

while (my $line = <$data>) {
    chomp $line;

    my @lineAr = split(/\t/, $line);

    my $qseq = $lineAr[$QSEQ_COLUMN];

    my $evalue = $lineAr[$EVALUE_COLUMN];

    push( @{$values{$qseq}}, $evalue);
}

my %seqSum;

foreach my $key (keys %values) {
    my $sum = 0;
    foreach(@{$values{$key}}) {
        $sum += $_;
    }
    $seqSum{$key} = $sum;
}

my $bestRepresentative = reduce { $seqSum{$a} < $seqSum{$b} ? $a : $b } keys %seqSum;

open(OUT,">$outputFile")  or die "Cannot open file $outputFile For writing: $!";
print OUT "${group}\t${bestRepresentative}\n";
close OUT;

