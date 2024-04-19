#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Create a full singletons file with non-overlapping groups from all organism specific singleton files.

=head1 Input Parameters

=over 4

=item fileSuffix

A glob path to retrieve all singleton files

=back

=over 4

=item buildVersion

An integer indicating the build version of the orthofinder runs

=back

=over 4

=item outputFile

The path to the full singletons file

=back

=cut

my ($fileSuffix,$lastGroup,$buildVersion,$outputFile);

&GetOptions("fileSuffix=s"=> \$fileSuffix,
            "buildVersion=s"=> \$buildVersion,
            "outputFile=s"=> \$outputFile);

# Get all organism specific singleton files
my @singletonFiles = glob("*.${fileSuffix}");

open(OUT, ">singletonsFull.dat") || die "Could not open full singletons file: $!";

# for each organism specific singleton file
foreach my $file(@singletonFiles) {

    open(my $data, "<$file");

    while (my $line = <$data>) {
        chomp $line;
	
	print OUT "$line\n";

    }

    close $data;
}

close OUT;
