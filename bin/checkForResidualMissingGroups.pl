#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $inputDir = $ARGV[0];
my $buildVersion = $ARGV[1];
my $residualBuildVersion = $ARGV[2];
my $groupFile = $ARGV[3];

my $lastGroup;
open(my $data, '<', $groupFile);
while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /(OG\S*\d+_\d+):\s(.+)/) {
        $lastGroup = $1;
    }
    else {
        die "Improper file format $line\n";
    }
}
close $data;

print "$lastGroup\n";

my $lastGroupFile = $inputDir . "/" . $lastGroup . ".sim";

open(OUT,">missingGroups.txt")  or die "Couldn't open missingGroups.txt: $!";

# Creating group prefix. Will be combined with number to create full group name.
my $groupPrefix = "OGR${buildVersion}r${residualBuildVersion}_";

# Int holder for counting.
my $currentGroupInt = 0;

# Will take an int like 0 and return ${inputDir}/OGR${buildVersion}_0000000.sim;
my $currentGroupFile = &reformatGroup($currentGroupInt, $groupPrefix, $inputDir);

# Creating array of group similarity files.
my @files = <$inputDir/*.sim>;

my $fileCounter = 0;
# For every group similarity file.
foreach my $file (@files) {

    # Until we have made it to the next group.
    until ($currentGroupFile eq $file) {
        
        # Convert current group file into group formatting. Ex: ./OGR7_0000000.sim to OGR7_0000000.
	$currentGroupFile =~ s/${inputDir}\///g;
        $currentGroupFile =~ s/\.sim//g;

        # Print out missing group for future processing.
        print OUT "$currentGroupFile\n";
        print "$currentGroupFile\n";	

        # Increase currentGroupInt by one to look for the next group.
        $currentGroupInt += 1;

        # Convert int to file format.
        $currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix, $inputDir);
    }
    if ($currentGroupFile ne $lastGroupFile) {
 
        # We have the file. Move to checking for next.

        # Increase currentGroupInt by one to look for the next group.
        $currentGroupInt += 1;

        # Convert int to file format.
        $currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix, $inputDir);
    }
}

until ($currentGroupFile eq $lastGroupFile) {
    $currentGroupFile =~ s/${inputDir}\///g;
    $currentGroupFile =~ s/\.sim//g;

    # Print out missing group for future processing.
    print OUT "$currentGroupFile\n";

    # Increase currentGroupInt by one to look for the next group.
    $currentGroupInt += 1;

    # Convert int to file format.
    $currentGroupFile = &reformatGroup($currentGroupInt,$groupPrefix, $inputDir);
}

if( !-e $lastGroupFile ) {
    print OUT "$lastGroup\n";
}

close OUT;

sub reformatGroup {
    my ($groupInt,$groupPrefix,$inputDir) = @_;

    # Convert 0 to 0000000 or 235 to 0000235.
    my $reformattedGroupInt = sprintf("%07d", $groupInt);

    # Example ./OGR7_0000000.sim.
    my $reformattedGroup = "${inputDir}/${groupPrefix}${reformattedGroupInt}.sim";
    return $reformattedGroup;
}
