#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Receive a fasta file and split into into separate organism fastas. Needed for orthofinder.

=head1 Input Parameters

=over 4

=item input

The fasta file to be split

=back

=over 4

=item outputDir

The directory to write the output files

=back

=cut

my ($inputFasta,$proteomeDir,$outputDir);

&GetOptions("inputFasta=s"=> \$inputFasta,
	    "proteomeDir=s"=> \$proteomeDir,
            "outputDir=s"=> \$outputDir);

open(my $residual, '<', $inputFasta) || die "Could not open file $inputFasta: $!";

my $organism;
my %residualSequenceHash;

# Foreach line in residual fasta
while (my $line = <$residual>) {
    # If it is a def line
    if ($line =~ /^>(\S+)/) {
	# Store the sequence id as a residual
	$residualSequenceHash{$1} = 1;
    }
}

# Creating array of fasta files.
my @files = <$proteomeDir/*.fasta>;

my $isResidual = 0;

# For every fasta file.
foreach my $file (@files) {

    # Retrieving current organism abbrev
    my $organismAbbrev = $file;
    $organismAbbrev =~ s/${proteomeDir}\///g;
    $organismAbbrev =~ s/\.fasta//g;

    open(my $sequences, '<', $file) || die "Could not open file $file: $!";
    open(my $organismFasta, '>', "$outputDir/$organismAbbrev.fasta") || die "Could not open file $outputDir/$organismAbbrev.fasta: $!";

    while (my $line = <$sequences>) {
    # If it is a def line
	if ($line =~ /^>(\S+)/) {
	    # If the sequence is residual
            if($residualSequenceHash{$1} == 1) {
	        print $organismFasta "$line";
                $isResidual = 1;
	    }
	    else {
                $isResidual = 0;
	    }
        }
	# Is a sequence line
        else {
	    # print sequence if it is a residual sequence
	    if($isResidual == 1) {
	        print $organismFasta "$line";
	    }
        }
    }
}
