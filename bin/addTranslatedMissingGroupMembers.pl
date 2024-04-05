#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Chooses a best representative from a hierarchal ortholog group thats shares no internal blast results, and adds the best representative to the best representatives file.

=head1 Input Parameters

=over 4

=item sequenceMapping

File containing sequence orthoFinder internal mappings

=back

=over 4

=item groupMapping

N0.tsv OrthoFinder group file

=back

=over 4

=item missingGroups

File containing groups that did not share internal blast results

=back

=cut

my ($sequenceMapping,$missingGroups,$groupMapping);

&GetOptions("sequenceMapping=s"=> \$sequenceMapping,
            "groupMapping=s"=> \$groupMapping,
            "missingGroups=s"=> \$missingGroups);

my %sequenceMap = &makeSequenceMappingHash($sequenceMapping);

open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";

while (my $line = <$missing>) {
    chomp $line;
    
    # Save full missing group ID for later
    my $missingGroup = $line;
    
    # Reformat to OrthoFinder HOG formatting
    $line =~ s/OG\d+_/N0\.HOG/g;
    
    # Retrieve the group information from N0.tsv
    my $groupLine = `grep "$line" $groupMapping`;
    
    # Make sure file is correct format and retrieve sequences
    if ($groupLine =~ /^N0\.HOG\d+\tOG\d+\tn\d+\t(.*)/ || $groupLine =~ /^N0\.HOG\d+\tOG\d+\t-\t(.*)/) {
        my $groupSequences = $1;
	
	# Sequences are comma and space delimited for sequences from the same organism. Make these all space delimited.
        $groupSequences =~ s/ //g;
        $groupSequences =~ s/,/ /g;
	
	# Sequences are tab delimited when switching to a different organism. Make these all space delimited.	
        $groupSequences =~ s/\t+/ /g;
	
	# Created an array to hold all sequences within the missing group
        my @missingSequences = split(/\s/, $groupSequences);
	@missingSequences = grep { $_ ne '' } @missingSequences;
	
	# Assign the first sequence as the best representative for the group.
        my $bestRepSequence = $sequenceMap{$missingSequences[0]};
	
	# Print out the missing group ID and the sequence representing it.
	print "$missingGroup\t$bestRepSequence\n";
    }
    else {
        die "Improper group file format for line $line\n";
    }
}

close $missing;

=pod

=head1 Subroutines

=over 4

=item makeSequenceMappingHash()

The process takes the sequence mapping file that holds the internal orthofinder mappings and creates a hash linking internal and real sequence IDs.

=back

=cut

sub makeSequenceMappingHash {
    my ($sequenceMapFile) = @_;
    my %sequenceMapping;

    # Open sequence mapping
    open(my $map, '<', $sequenceMapFile) || die "Could not open file $sequenceMapFile: $!";

    # For each mapping
    while (my $line = <$map>) {
        chomp $line;
	
	# Retrieve mapping and sequence
        my ($mapping, $sequence) = split(/:\s/, $line);

	# Create array holding all sequence info
        my @sequenceArray = split(/\s/, $sequence);

	# Associate real sequence ID (first value in sequenceArray) and it's internal mapping
        $sequenceMapping{$sequenceArray[0]} = $mapping;
    }
    
    close $map;
    return %sequenceMapping;
}
