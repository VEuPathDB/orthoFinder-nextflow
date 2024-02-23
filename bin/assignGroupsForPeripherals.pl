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

my ($result,$output,$groupFile);

&GetOptions("result=s"=> \$result,
            "output=s"=> \$output,
	    "groupFile=s"=> \$groupFile
            );

open(my $data, '<', $result) || die "Could not open file $result: $!";
open(OUT,">$output");
open(GRP,"<$groupFile");

my %coreGroupAssignments;
while (my $line = <GRP>) {
    chomp $line;
    if ($line =~ /^(OG\d+_\d+):\s(.+)/) {
        my $groupID = $1;
        my @seqArray = split(/\s/, $2);
	foreach my $seq (@seqArray) {
            $coreGroupAssignments{$seq} = $groupID;
	}
    }
    else {
	die "Improper group file format: $!";
    }
}

my %seqBestHit;

# for each pair wise result
while (my $line = <$data>) {
    chomp $line;

    # Retrieve the values
    my @lineAr = split(/\t/, $line);

    # Retrieve the qseq, seq (best reps are identified by the group they represent) and the evalue
    my $qseq = $lineAr[0];
    my $sseq = $lineAr[1];
    my $evalue = $lineAr[10];

    # If first result for this sequence
    unless($seqBestHit{$qseq}) {
	# Set the sequences group and e-value
        $seqBestHit{$qseq}->{evalue} = $evalue;
        $seqBestHit{$qseq}->{sseq} = $sseq;
    }

    # If we found a better match
    if($seqBestHit{$qseq}->{evalue} > $evalue) {
	# Set the new evalue and group
        $seqBestHit{$qseq}->{evalue} = $evalue;
        $seqBestHit{$qseq}->{sseq} = $sseq;
    }

}

# For each sequence, print out it's group assignment
foreach my $seq (keys %seqBestHit) {
    my $seqBestMatch = $seqBestHit{$seq}->{sseq};
    print OUT "$seq\t" . $coreGroupAssignments{$seqBestMatch} . "\n";
}
