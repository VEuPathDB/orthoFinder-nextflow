#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

=pod

=head1 Description: 

Determine the best representative per group by calculating the lowest average e-value across all sequences within a group.

=head1 Input Parameters

=over 4

=item groupFile 

The pairwise blast results file. Results are split by group within the file.

=back 

=cut

my ($groupFile);

&GetOptions("groupFile=s"=> \$groupFile);

# Set subject sequence column and evalue column for retrieving those values.
my $SSEQ_COLUMN = 1;
my $EVALUE_COLUMN = 10;

# Open file of group blast results.
open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";

my $group;
my %values;

# For each group blast result.
while (my $line = <$data>) {
    chomp $line;
    next unless($line);

    # We have moved onto a new group. Calculate values for the last group.
    if($line =~ /==> (\S+).sim <==/) {

        &determineBestRepAndPrintGroup($group, \%values) if($group);

	# Retrieve new group and clear previous values.
        $group = $1;
        %values = ();
	
        next;
    }

    # Get array of pairwise blast results
    my @lineAr = split(/\t/, $line);

    # Retrieve query sequence
    my $sseq = $lineAr[$SSEQ_COLUMN];

    # Retrieve evalue
    my $evalue = $lineAr[$EVALUE_COLUMN];

    my $exponent;

    if ($evalue =~ /\S+e-(\d+)/) {
        $exponent = $1;
    }
    else {
        $exponent = 2;
    }   
    
    # Sum total of exponents 
    $values{$sseq}->{sum} += $exponent;
}

# Calculate results for last group in file.
&determineBestRepAndPrintGroup($group, \%values) if($group);

1;

=pod

=head1 Subroutines

=over 4

=item determineBestRepAndPrintGroup()

This process takes the group ID and the values object. The values object contains the sum of the exponents from the evalues of blast hits. This process is called once per group. I will run through all of the sseqs in the values object and determine which sequence has the highest sum of exponents. This sequence is identified as the best representative for this group.

=back

=cut

sub determineBestRepAndPrintGroup {
    my ($group, $values) = @_;

    # Small place holder value.
    my $highestExponent = 0;
    my $bestRepresentative;

    # For every query sequence.
    foreach my $sseq (keys %values) {

        my $sumExponents = $values{$sseq}->{sum};

	# If this is the highest sum of exponents we have seen for this group, mark it as the best representative and save it's sum of exponents for next comparison.
        if($sumExponents >= $highestExponent) {
            $bestRepresentative = $sseq;
            $highestExponent = $sumExponents;
        }
    }

    # Print out the group and it's best representative for future processing.
    print "${group}\t${bestRepresentative}\n";

}
