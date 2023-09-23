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



my $in  = Bio::SeqIO->new(-file => $input ,
                         -format => 'Fasta');

my $unambiguous = Bio::SeqIO->new(-file => ">$unambiguousOutput" ,
                                   -format => 'Fasta');

my $ambiguous = Bio::SeqIO->new(-file => ">$ambiguousOutput" ,
                                -format => 'Fasta');


while ( my $seq = $in->next_seq() ) {
    if($seq->seq() =~  /[EFILPQ]/) {
        $unambiguous->write_seq($seq);
    }
    else {
        $ambiguous->write_seq($seq);
    }
}


1;
