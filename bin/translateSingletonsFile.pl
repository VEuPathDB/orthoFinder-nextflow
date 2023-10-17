#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($singletons,$sequenceMapping);

&GetOptions("singletons=s"=> \$singletons,
            "sequenceMapping=s"=> \$sequenceMapping);

my %group_mapping = &makeGroupMappingHash($singletons);

my %mapping_sequence = &makeMappingSequenceHash($sequenceMapping);


open(OUT, '>translated.out') || die "Could not open file translated.out: $!";

foreach my $key (keys %group_mapping) {
    my $mapping = $group_mapping{$key};
    my $sequence = $mapping_sequence{$mapping};
    print OUT "$key: $sequence\n";
}

close OUT;

# ========================== Subroutines =================================

sub makeGroupMappingHash {
    my ($singletons) = @_;
    my %group_mapping;
    open(my $data, '<', $singletons) || die "Could not open file $singletons: $!";
    while (my $line = <$data>) {
        chomp $line;
        my ($group, $mapping) = split(/\t/, $line);
        $group_mapping{$group} = $mapping;
    }
    close $data;
    return %group_mapping;
}

sub makeMappingSequenceHash {
    my ($singletons) = @_;
    my $mapping_sequence;
    open(my $map, '<', $sequenceMapping) || die "Could not open file $sequenceMapping: $!";
    while (my $line = <$map>) {
        chomp $line;
        my ($mapping, $sequence) = split(/:\s/, $line);
        my @sequenceArray = split(/\s/, $sequence);
        $mapping_sequence{$mapping} = $sequenceArray[0];
    }
    close $map;
    return %mapping_sequence;
}
