#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groups,$blastFile);

&GetOptions("groups=s"=> \$groups,
	    "blastFile=s"=> \$blastFile);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";
open(my $blast, '<', $blastFile) || die "Could not open file $blastFile: $!";

# Make hash to store sequence group assignments
my %seqToGroup;
# For each line in groups file
while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^(OG\d+_\d+):\s(.+)/) {
	my $groupId = $1;
        my @seqArray = split(/\s/,$2);
	foreach my $seq (@seqArray) {
            # Record the group assignment for each sequence
            $seqToGroup{$seq} = $groupId;
        }
    }
    else {
	die "Improper file format for groups file $groups\n";
    }
}
close $data;

my $currentGroupId = "";
my $groupId;
while (my $line = <$blast>) {
    chomp $line;
    if ($line =~ /(\S+)\t(\S+).+/) {
	my $query = $1;
	my $subject = $2;
	my $queryGroupId = $seqToGroup{$query};
	my $subjectGroupId = $seqToGroup{$subject};
        $groupId = $queryGroupId;
	if ($queryGroupId && $subjectGroupId) {
	    if ($queryGroupId eq $subjectGroupId) {
	        if ($currentGroupId eq $groupId) {
                    print OUT "$line\n";
	        }
	        else {
                    close OUT if($currentGroupId);
	            open(OUT,">>${groupId}.sim")  || die "Could not open file ${groupId}.sim: $!";
	            print OUT "$line\n";
	            $currentGroupId = $groupId;
	        }
	    }
        }
    }
    else {
	die "Improper file format for line $line\n";
    }
}	
close OUT;
