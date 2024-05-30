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
my %groupSizeHash;
# For each line in groups file
while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /(OG\d+_\d+):\s(.+)/) {
	my $groupId = $1;
        my $seqLine = $2;
	my @seqArray = split(/\s/, $seqLine);
	foreach my $seq (@seqArray) {
            # Record the group assignment for each sequence
	    $seqToGroup{$seq} = $groupId;
	    $groupSizeHash{$groupId} += 1;
	}
    }
    else {
	die "Improper file format for groups file $groups\n";
    }
}
close $data;

my $currentGroupId = "";
my $groupId;
my %groupUsedHash;
while (my $line = <$pro>) {
    chomp $line;
    if ($line =~ /^>(\S+).*/) {
	$groupId = $seqToGroup{$1};
	# If seq in our group subset
	if ($groupId) {
	    $groupUsedHash{$groupId} += 1;
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

foreach my $group (keys %groupUsedHash) {
    if ($groupUsedHash{$group} != $groupSizeHash{$group}) {
	die "All group seqs were not put in $group group fasta file. $groupUsedHash{$group} out of $groupSizeHash{$group}";
    }
}
