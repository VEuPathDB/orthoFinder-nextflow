#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 Description

Takes a directory of orthogroup blast results and checks to see what groups are missing. These are printed out to a missing groups file for later processing.

=head1 Input Parameters

=over 4

=item inputDir

Directory containing ortholog group diamond results.

=back

=over 4

=item buildVersion

Build version of OrthoMCL.

=back

=over 4

=cut

# Input species ID file
my $inputDir = $ARGV[0];
my $buildVersion = $ARGV[1];

open(OUT,">missingGroups.txt");

# Creating group prefix. Will be combined with number to create full group name.
my $groupPrefix = "OG${buildVersion}_";

# Int holder for counting.
my $currentGroupInt = 0;

# Will take an int like 0 and return ${inputDir}/OG${buildVersion}_0000000.sim;
my $currentGroupFile = &reformatGroup($currentGroupInt, $groupPrefix, $inputDir);

# Creating array of group similarity files.
my @files = <$inputDir/*.sim>;

# For every group similarity file.
foreach my $file (@files) {

    # Until we have made it to the next group.
    until ($currentGroupFile eq $file) {

	# Convert current group file into group formatting. Ex: ./OG7_0000000.sim to OG7_0000000.
	$currentGroupFile =~ s/${inputDir}\///g;
	$currentGroupFile =~ s/\.sim//g;

	# Print out missing group for future processing.
        print OUT "$currentGroupFile\n";

	# Increase currentGroupInt by one to look for the next group.
	$currentGroupInt += 1;

	# Convert int to file format.
	$currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix, $inputDir);
    }

    # We have the file. Move to checking for next.

    # Increase currentGroupInt by one to look for the next group.
    $currentGroupInt += 1;

    # Convert int to file format.
    $currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix, $inputDir);
}

close OUT;

=pod

=head1 Subroutines

=over 4

=item reformatGroup()

The process takes the groupInt, groupPrefix, and the inputDir. It uses these to take an integer used for counting and converts it to the next file name we will be looking for.

=back

=cut

sub reformatGroup {
    my ($groupInt,$groupPrefix,$inputDir) = @_;

    # Convert 0 to 0000000 or 235 to 0000235.
    my $reformattedGroupInt = sprintf("%07d", $groupInt);

    # Example ./OG7_0000000.sim.
    my $reformattedGroup = "${inputDir}/${groupPrefix}${reformattedGroupInt}.sim";
    return $reformattedGroup;
}
