#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

use Bio::SeqIO;

my ($input,$ambiguousOutput, $unambiguousOutput);

&GetOptions("input=s"=> \$input,
            "ambiguous=s"=> \$ambiguousOutput,
            "unambiguous=s"=> \$unambiguousOutput
    );

# The point of this script is to ensure that a sequence with unambigous amino acids is in the first 10 sequences of the fasta. This is due to orthofinder throwing an error, indicating it cannot identify if the sequence is NA or AA.

# SeqIO object for organism fasta
my $in  = Bio::SeqIO->new(-file => $input ,
                         -format => 'Fasta');

# Prepare unambigous and ambigous output fasta files
my $unambiguous = Bio::SeqIO->new(-file => ">$unambiguousOutput" ,
                                   -format => 'Fasta');

my $ambiguous = Bio::SeqIO->new(-file => ">$ambiguousOutput" ,
                                -format => 'Fasta');

# For each sequence in input fasta
while ( my $seq = $in->next_seq() ) {
    # If sequence contains specified letters, write to unambiguous file
    if($seq->seq() =~  /[EFILPQ]/) {
        $unambiguous->write_seq($seq);
    }
    # Else write to ambigous file
    else {
        $ambiguous->write_seq($seq);
    }
}

# The ambigous file is concatenated to the end of the unambigous file, ensuring that we have the full fasta and that an unambigous sequence is in the first 10 sequences

1;
