#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

=head1 Description
Split a proteome into multiple group files using group assignments,
processing one group at a time for large datasets.
Logs bad headers instead of dying.
=cut

my ($groups, $proteome);
GetOptions(
    "groups=s"   => \$groups,
    "proteome=s" => \$proteome
    ) or die "Usage: $0 --groups group_file --proteome proteome_file\n";

# -------------------------
# 0) Log file for problems
# -------------------------
open(my $log, '>', "bad_headers.log") or die "Cannot open bad_headers.log: $!";

# -------------------------
# 1) Read group assignments
# -------------------------
open(my $data, '<', $groups) or die "Could not open $groups: $!";

my %seqToGroup;
my %groupSizeHash;
my %groupsHash;
my $groupAssignmentCount = 0;

print "Reading group assignments\n";
system('date');

while (my $line = <$data>) {
    chomp $line;
    $groupAssignmentCount++;
    print "Processed $groupAssignmentCount groups\n" if $groupAssignmentCount % 100 == 0;

    if ($line =~ /(OG\w*\d+_\d+):\s(.+)/) {
        my $groupId = $1;
        my @seqArray = split(/\s+/, $2);
        foreach my $seq (@seqArray) {
            $seq =~ s/_pseudo/:pseudo/g;
            $seqToGroup{$seq} = $groupId;
            push @{$groupsHash{$groupId}}, $seq;
            $groupSizeHash{$groupId}++;
        }
    } else {
        die "Bad group line: $line\n";
    }
}
close $data;

print "Done reading group assignments\n";
system('date');

# -------------------------
# 2) Read proteome sequences
# -------------------------
print "Reading proteome sequences\n";
system('date');
open(my $pro, '<', $proteome) or die "Could not open $proteome: $!";
my %seqToSeq;
my $currentSeqId = "";

while (my $line = <$pro>) {
    chomp $line;
    if ($line =~ /^>(\S+)/) {
        $currentSeqId = $1;
        $seqToSeq{$currentSeqId} = "";
    }
    elsif ($currentSeqId) {
        $seqToSeq{$currentSeqId} .= $line;
    }
}
close $pro;
print "Done reading proteome sequences\n";
system('date');

# -------------------------
# 3) Process one group at a time
# -------------------------
print "Processing groups\n";
system('date');
foreach my $groupId (sort keys %groupsHash) {
    print "Processing $groupId\n";
    my $filename = "${groupId}.fasta";
    open(my $out, '>', $filename) or do {
        print $log "Cannot open $filename: $!\n";
        next;
    };
    foreach my $seqId (@{$groupsHash{$groupId}}) {
        if (exists $seqToSeq{$seqId}) {
            print $out ">$seqId\n$seqToSeq{$seqId}\n";
        } else {
            $seqId =~ s/_RNA/:RNA/g;
            $seqId =~ s/_mRNA/:mRNA/g;
            if (exists $seqToSeq{$seqId}) {
                print $out ">$seqId\n$seqToSeq{$seqId}\n";
            }
            else {
                print $log "Sequence $seqId not found in proteome for group $groupId\n";
            }
        }
    }
    close $out;
}
print "Done processing groups\n";
system('date');

# -------------------------
# 4) Completeness check
# -------------------------
foreach my $group (keys %groupSizeHash) {
    my $written = @{$groupsHash{$group}};
    if ($written != $groupSizeHash{$group}) {
        print $log "Group $group incomplete: $written of $groupSizeHash{$group} sequences written\n";
        die "Group $group incomplete: $written of $groupSizeHash{$group} sequences written\n";
    }
}

close $log;
print "Processing complete. See bad_headers.log for warnings.\n";
