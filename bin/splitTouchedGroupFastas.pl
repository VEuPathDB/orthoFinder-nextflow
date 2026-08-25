#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Write one small fasta per "touched" group (a group whose membership changed
this run) containing just that group's current members, so a best
representative can be recomputed for touched groups only -- instead of
rerunning full pairwise similarity over every group.

=head1 Input Parameters

=over 4

=item groupFile

Current (post-merge) combined groups file: "GROUPID: seq1 seq2 ...".

=item touchedGroups

One group ID per line -- the groups to extract.

=item proteome

Fasta file(s) containing every sequence referenced by touchedGroups (may be
passed multiple times).

=item outputDir

Directory to write "<groupID>.fasta" files into.

=back

=cut

my ($groupFile, $touchedGroups, @proteomes, $outputDir);

&GetOptions("groupFile=s" => \$groupFile,
            "touchedGroups=s" => \$touchedGroups,
            "proteome=s" => \@proteomes,
            "outputDir=s" => \$outputDir);

open(my $touchedFh, '<', $touchedGroups) || die "Could not open file $touchedGroups: $!";
my %touchedGroup;
while (my $line = <$touchedFh>) {
    chomp $line;
    next unless length($line);
    $touchedGroup{$line} = 1;
}
close($touchedFh);

open(my $grpFh, '<', $groupFile) || die "Could not open file $groupFile: $!";
my %seqToGroup;
while (my $line = <$grpFh>) {
    chomp $line;
    next unless length($line);

    if ($line =~ /^(\S+):\s(.+)/) {
        my ($groupId, $seqString) = ($1, $2);
        next unless $touchedGroup{$groupId};

        foreach my $seq (split(/\s+/, $seqString)) {
            $seqToGroup{$seq} = $groupId;
        }
    }
    else {
        die "Improper group file format: $line";
    }
}
close($grpFh);

foreach my $proteome (@proteomes) {
    open(my $fastaFh, '<', $proteome) || die "Could not open file $proteome: $!";

    my $currentGroup;
    while (my $line = <$fastaFh>) {
        if ($line =~ /^>(\S+)/) {
            my $seqId = $1;
            $currentGroup = $seqToGroup{$seqId}; # undef (and thus skipped below) if not a touched-group member
        }

        next unless $currentGroup;

        # Open/append/close per line rather than holding one handle open per
        # touched group -- a real incremental build can touch thousands of
        # groups at once, which blows past the OS's open-file-descriptor limit.
        open(my $out, '>>', "$outputDir/$currentGroup.fasta") || die "Could not open $outputDir/$currentGroup.fasta for writing: $!";
        print $out $line;
        close($out);
    }
    close($fastaFh);
}
