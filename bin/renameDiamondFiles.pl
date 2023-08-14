#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $species_id_file = $ARGV[0];
my $sequences_id_file = $ARGV[1];
my $output_directory = $ARGV[2];

# Read species ID file
open my $fh_species, '<', $species_id_file or die "Cannot open $species_id_file: $!";
my %species_map;
while (my $line = <$fh_species>) {
    chomp $line;
    if ($line =~ /^(\d+):\s+(\S+)\.fasta\.fasta/) {
        my ($id, $species) = ($1, $2);
        $species_map{$id} = $species;
    }
}
close $fh_species;

# Read sequences ID file
open my $fh_sequences, '<', $sequences_id_file or die "Cannot open $sequences_id_file: $!";
my %sequences_map;
while (my $line = <$fh_sequences>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s+(.+)/) {
        my ($new, $original) = ($1, $2);
        $sequences_map{$new} = $original;
    }
}
close $fh_sequences;

# Rename files in the output directory
opendir(my $dh, $output_directory) or die "Cannot open directory $output_directory: $!";
while (my $file = readdir($dh)) {
    next unless $file =~ /^Blast(\d+)_(\d+)\.txt\.gz/;
    my ($first_id, $second_id) = ($1, $2);
    $file = "$output_directory/$file";
    system("sed -i ';' $file");
    system("gunzip $file");
    $file =~ s/\.gz//g;
    if (exists $species_map{$first_id}) {
        my $first_species = $species_map{$first_id};
	my $second_species = $species_map{$second_id};
	my $new_name = "$output_directory/$first_species" . "_" . "$second_species" . "\.txt";
	if (-e "/previousBlasts/${first_species}_${second_species}.txt.gz") {
	    system("cp /previousBlasts/${first_species}_${second_species}.txt.gz ${new_name}.gz");
	}
	else {
            system("mv $file $new_name");
            print "Renamed: $file -> $new_name\n";
	    open my $fh_new, '<', "$new_name" or die "Cannot open $new_name: $!";
	    my $new_name_temp = "$new_name" . ".temp";
	    open(OUT,">$new_name_temp");
	    while (my $line = <$fh_new>) {
	        chomp $line;
	        if ($line =~ /^(\d+_\d+)\s+(\d+_\d+)(.*)/) {
		    my ($new_first_sequence, $new_second_sequence, $data) = ($1,$2,$3);
		    my $original_first_sequence = $sequences_map{$new_first_sequence};
		    my $original_second_sequence = $sequences_map{$new_second_sequence};
		    print OUT "$original_first_sequence\t$original_second_sequence$data\n";
	        }
 	        else {
	            die "$line Invalid blast format\n";
	        }
            }
	    rename($new_name_temp, $new_name) or die "Cannot rename $new_name_temp to $new_name: $!";
	    system("gzip $new_name");
	}
    } else {
        print "Warning: No species found for ID $first_id. Skipping file: $file\n";
    }  
}
closedir($dh);
