#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Take the core groups file from the core workflow, and integrate peripheral sequences after they have been assigned to groups.

=head1 Input Parameters

=over 4

=item coreGroup

The groups file generate from the core workflow

=back

=over 4

=item peripheralGroup

Input file holding peripheral sequences and their group assignments

=back

=cut

my ($coreGroup,$peripheralGroup,$output);

&GetOptions("coreGroup=s"=> \$coreGroup,
	    "peripheralGroup=s"=> \$peripheralGroup,
            "output=s"=> \$output);

open(my $core, '<', $coreGroup) || die "Could not open file $coreGroup: $!";
open(my $peripheral, '<', $peripheralGroup) || die "Could not open file $peripheralGroup: $!";
open(OUT,">$output");

# For each core group
while (my $line = <$core>) {
    chomp $line;
    if ($line =~ /^(OG\d+_\d+):\s(.+)/) {
	# Get the groupID
	my $groupId = $1;
	# Get the group sequences
	my $groupSeqs = $2;
	# Create array of sequences
	my @sequences = split(/\s/, $groupSeqs);
	# Place all sequences that have been assigned to this core group into a temp group file
	`grep "${groupId}" $peripheralGroup > ${groupId}.tmp`;
	open(my $idFile, "<${groupId}.tmp") || die "Could not open file ${groupId}.txt: $!";
	# For every peripheral sequence assigned to this group
	while (my $idLine = <$idFile>) {
	    chomp $idLine;
	    # Format is group \t sequence
	    if ($idLine =~ /^(\S+)\t(\S+)/) {
		my $peripheralSeq = $1;
		# Push the peripheral sequence to the core sequences array
	        push(@sequences,$peripheralSeq);
	    }
	    else {
		die "Improper peripheralFile format\n";
	    }	
        }
	close $idFile;
	my $sequenceString = join(' ', @sequences);
	# Print out the group ID and all of the core and peripheral sequence assigned to it
        print OUT "$groupId: $sequenceString\n";
	# Remove the temp file
	unlink "${groupId}.tmp" or warn "Could not unlink ${groupId} temp file: $!";
    }
    else {
	die "Improper groupFile format\n$line\n";
    }   
}	
