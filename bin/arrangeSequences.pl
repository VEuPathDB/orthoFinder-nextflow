#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$output);

&GetOptions("input=s"=> \$input,
            "output=s"=> \$output);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my ($currentOrg, $organism, $sequence);

while (my $line = <$data>) {
    if ($line =~ /^>/) {
	$currentOrg = $line;
    }
    elsif ($line =~  /[EFILPQ]/) {
	$organism = $currentOrg;
	$sequence = $line;
	last;
    }
    else {
	next;
    }
}	

die "Fasta file $input does not contain necessary Amino Acids" unless ($organism);

close $data;

open(OUT,">./$output");
print OUT "$organism$sequence";
close OUT;

open(OUT,">>./$output");
open($data, '<', $input) || die "Could not open file $input: $!";
while (my $line = <$data>) {
    if ($line ne $organism && $line ne $sequence) {
	print OUT $line;
    }
    else {
	next;
    }
}
