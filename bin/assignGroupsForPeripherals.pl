#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Assign peripheral sequences to groups by seeing which group best representative the qseq matched best with (had the lowest e-value). If the sequence doesn't match with any best rep, it will be identified as a residual sequence.

=head1 Input Parameters

=over 4

=item result

File containing diamond similarity results

=back

=over 4

=item outputFile

Output file to which to write the sequence and it's group assignment

=back

=cut

my ($result,$output);

&GetOptions("result=s"=> \$result, # Sorted diamond similarity results
            "output=s"=> \$output);

open(my $data, '<', $result) || die "Could not open file $result: $!";
open(OUT,">$output");

my %seqToGroup;

# for each pair wise result
while (my $line = <$data>) {
    chomp $line;

    # Retrieve the values
    my @lineAr = split(/\t/, $line);

    # Retrieve the qseq, seq (best reps are identified by the group they represent) and the evalue
    my $qseq = $lineAr[0];
    my $group = $lineAr[1];
    my $evalue = $lineAr[10];

    # If first result for this sequence
    unless($seqToGroup{$qseq}) {
	# Set the sequences group and e-value
        $seqToGroup{$qseq}->{evalue} = $evalue;
        $seqToGroup{$qseq}->{group} = $group;
    }

    # If we found a better match
    if($seqToGroup{$qseq}->{evalue} > $evalue) {
	# Set the new evalue and group
        $seqToGroup{$qseq}->{evalue} = $evalue;
        $seqToGroup{$qseq}->{group} = $group;
    }

}

# For each sequence, print out it's group assignment
foreach my $seq (keys %seqToGroup) {
    print OUT "$seq\t" . $seqToGroup{$seq}->{group} . "\n";
}
