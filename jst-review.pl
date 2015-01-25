#!/usr/bin/perl
use strict;

use Review::JST;

my $text;
while(<>) {
        $text .= $_;
}
my %review = Review::JST::review($text);
my %found_problems;
foreach my $file (sort keys %review) {
        print "\n$file\n";
        foreach my $line_num (sort { $a <=> $b } keys %{$review{$file}}) {
                my @line = @{$review{$file}{$line_num}};
                print "$line[0] $line_num: +$line[2]\n";
                $found_problems{$line[0]}++;
        }
}

print "\nFound these problems in the patch:\n";
foreach my $problem (sort keys %found_problems) {
        print "$problem: $Review::JST::reasons{$problem}\n";
}
