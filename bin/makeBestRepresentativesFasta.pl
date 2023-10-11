#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;

# Takes fasta as stdin and uses the bestReps file to map to groups

my ($bestReps,$fasta,$isResidual, $outputFile);

&GetOptions("bestReps=s"=> \$bestReps, # Tab seperated file with group and seqID
            "outputFile=s" => \$outputFile); # Output best rep fasta file

my $in  = Bio::SeqIO->new(-fh => \*STDIN,
                          -format => 'Fasta');

my $bestRepsFasta = Bio::SeqIO->new(-file => ">$outputFile" ,
                                   -format => 'Fasta');


open(MAP, '<', $bestReps) || die "Could not open file $bestReps: $!";

my %map;
while (my $line = <MAP>) {
    chomp $line;
    my ($group, $repseq) = split(/\t/, $line);
    $map{$repseq} = $group;
}
close MAP;

while ( my $seq = $in->next_seq() ) {
    my $seqId = $seq->id();
    my $group = $map{$seqId};
    die "No Group defined for Seq $seqId" unless($group);

    $seq->id($group);
    $bestRepsFasta->write_seq($seq);
}

1;
