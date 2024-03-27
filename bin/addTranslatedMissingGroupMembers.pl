#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($lastGroup,$sequenceMapping,$missingGroups,$groupMapping,$singletonsFile,$version);

&GetOptions("lastGroup=s"=> \$lastGroup,
            "sequenceMapping=s"=> \$sequenceMapping,
            "groupMapping=s"=> \$groupMapping,
            "singletonsFile=s"=> \$singletonsFile,
            "missingGroups=s"=> \$missingGroups,
            "version=i"=>\$version);

my %sequenceMap = &makeSequenceMappingHash($sequenceMapping);
open(OUT, '>>', $singletonsFile) || die "Could not open file $singletonsFile: $!";

$lastGroup =~ s/OG\d+_//g;
$lastGroup += 1;

open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";
while (my $line = <$missing>) {
    chomp $line;
    my $missingGroup = $line;
    $line =~ s/OG\d+_/N0\.HOG/g;
    my $groupLine = `grep "$line" $groupMapping`;
    if ($groupLine =~ /^N0\.HOG\d+\tOG\d+\tn\d+\t(.*)/ || $groupLine =~ /^N0\.HOG\d+\tOG\d+\t-\t(.*)/) {
        my $groupSequences = $1;
        $groupSequences =~ s/ //g;
        $groupSequences =~ s/,/ /g;
        $groupSequences =~ s/\t+/ /g;
        my @missingSequences = split(/\s/, $groupSequences);
	@missingSequences = grep { $_ ne '' } @missingSequences;
	my $addedBestRep = 0;
        for my $sequence (@missingSequences) {
	    if ($addedBestRep == 0 ) {
		my $bestRepSequence = $sequenceMap{$sequence};
		print OUT "$missingGroup\t$bestRepSequence\n";
		$addedBestRep = 1;
		next;
	    }
	    else {
	        my $reformattedGroupInt = sprintf("%07d", $lastGroup);
	        my $translatedSequence = $sequenceMap{$sequence};
                print OUT "OG${version}_$reformattedGroupInt\t$translatedSequence\n";
	        $lastGroup += 1;
	    }
	}
    }
    else {
        die "Improper group file format for line $line\n";
    }
}
close $missing;
close OUT;

sub makeSequenceMappingHash {
    my ($sequenceMapFile) = @_;
    my %sequenceMapping;
    open(my $map, '<', $sequenceMapFile) || die "Could not open file $sequenceMapFile: $!";
    while (my $line = <$map>) {
        chomp $line;
        my ($mapping, $sequence) = split(/:\s/, $line);
        my @sequenceArray = split(/\s/, $sequence);
        $sequenceMapping{$sequenceArray[0]} = $mapping;
    }
    close $map;
    return %sequenceMapping;
}
