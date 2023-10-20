#!/usr/bin/perl

use strict;

use Getopt::Long;




my ($inputFile, $outputFileSuffix);

# the input file here MUST be sorted by the first column.  the first column will be used to name an output file $col[0]_${outputFileSuffx}

&GetOptions("input_file=s" => \$inputFile,
            "output_file_suffix=s" => \$outputFileSuffix,
    );


open(FILE, $inputFile) or die "Cannot open $inputFile for reading: $!";



my $prevOutputFileName = "BLAH";
my $fh;

my $count;

while(<FILE>) {
    chomp;

    my @a = split(/\t/, $_);
    my $group = shift @a;

    my $outputFileName = "${group}${outputFileSuffix}";

    unless($prevOutputFileName eq $outputFileName) {
        close $fh if($fh); #close the open one

        # NOTE:  Appending here is important.  we will be iterating over multiple blast/diamond files
        open($fh, ">>$outputFileName") or die "Cannot open file $outputFileName for writing: $!";
    }

    # always print the line
    print $fh join("\t", @a) . "\n";
    $prevOutputFileName = $outputFileName;
    $count++;
}

close $fh if($count);
close FILE;
