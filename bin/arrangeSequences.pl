#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$output);

&GetOptions("input=s"=> \$input,
            "output=s"=> \$output);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my ($currentOrg, $organism, $currentSeq, $sequence);
my $foundAAs = 0;

open(HOLD,">>./holdFile");
while (my $line = <$data>) {
    if ($line =~ /^>/) {
	$currentOrg = $line;
    }
    elsif ($line =~  /[EFILPQ]/ && $foundAAs == 0) {
	open(OUT,">./$output");
        print OUT "$currentOrg$line";
        close OUT;
	$foundAAs += 1;
    }
    else {
	print HOLD "$currentOrg$line";
    }
}	

die "Fasta file $input does not contain necessary Amino Acids" unless ($foundAAs == 1);

close $data;
close HOLD;

system("cat ./holdFile >> ./$output");
system("rm ./holdFile");
