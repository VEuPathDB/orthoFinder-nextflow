#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Split a proteome into multiple group files using group assignments.

=head1 Input Parameters

=over 4

=item groups

The file containing sequence group assignments.

=back

=over 4

=item proteome

The proteome file you wish to split

=back

=cut

my ($groups,$proteome);

&GetOptions("groups=s"=> \$groups,
	    "proteome=s"=> \$proteome);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";
open(my $pro, '<', $proteome) || die "Could not open file $proteome: $!";

# Make hash to store sequence group assignments
my %seqToGroup;
# For each line in groups file
while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^HOG\tOG\tGene/) {
        next;
    }
    if ($line =~ /^N0.H(OG\d+)\tOG\d+\t\S+\t(.+)/) {
	my $groupId = $1;
        my $seqLine = $2;
	$seqLine =~ s/^\t//g;
	$seqLine =~ s/\t/, /g;
	my @seqArray = split(/,\s/, $seqLine);
	foreach my $seq (@seqArray) {
	    # Resolve RNA line discrepency between OG file and fasta
	    $seq =~ s/_RNA/:RNA/g;
    	    $seq =~ s/_mRNA/:mRNA/g;
            # Record the group assignment for each sequence
	    print "$seq\t$groupId\n";
            $seqToGroup{$seq} = $groupId;
	}
    }
    else {
	die "Improper file format for groups file $groups.\nError line is $line\n";
    }
}
close $data;

my $currentGroupId = "";
my $groupId;
while (my $line = <$pro>) {
    chomp $line;
    if ($line =~ /^>(\S+).*/) {
	my $tempGroup = $1;
	$groupId = $seqToGroup{$tempGroup};
	# If seq in our group subset
	if ($groupId) {
	    if ($currentGroupId eq $groupId) {
                print OUT "$line\n";
	    }
	    else {
                close OUT if($currentGroupId);
		open(OUT,">>${groupId}.fasta")  || die "Could not open file ${groupId}.fasta: $!";
	        print OUT "$line\n";
	        $currentGroupId = $groupId;
	    }
	}
    }
    elsif ($groupId) {
        print OUT "$line\n";
    }
    else {
        next;
    }
}	
close OUT;
