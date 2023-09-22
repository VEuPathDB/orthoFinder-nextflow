#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$output);

&GetOptions("input=s"=> \$input,
            "output=s"=> \$output);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my $firstDefLine = 0;
open(TEMP,">>./temp_$input");
while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^>/ && $firstDefLine == 0) {
	print TEMP "$line\n";
	$firstDefLine+=1;
    }
    elsif ($line =~ /^>/ && $firstDefLine > 0) {
	print TEMP "\n$line\n";
    }
    else {
	print TEMP "$line";
    }
}

close $data;
close TEMP;

open(my $fixed, '<', "temp_$input");

my ($currentOrg, $organism, $currentSeq, $sequence);
my $foundAAs = 0;

open(HOLD,">>./holdFile");
while (my $line = <$fixed>) {
    chomp $line;
    if ($line =~ /^>/) {
	$currentOrg = $line;
    }
    elsif ($line =~  /[EFILPQ]/ && $foundAAs == 0) {
	open(OUT,">./$output");
        print OUT "$currentOrg\n$line\n";
        close OUT;
	$foundAAs += 1;
    }
    else {
	print HOLD "$currentOrg\n$line\n";
    }
}	

die "Fasta file $input does not contain necessary Amino Acids" unless ($foundAAs == 1);

close $fixed;
close HOLD;

system("cat ./holdFile >> ./$output");
system("rm ./holdFile");
