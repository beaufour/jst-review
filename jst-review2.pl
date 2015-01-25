#!/usr/bin/perl
use strict;
use Review::JST;
use LWP::Simple;

# todo: Escaping should be a parameter

########################################
# Get input
my $text;
my $url = shift;
if ($url) {
# Fetch from URL
    if ($url =~ /^\d+$/) {
	$url = "https://bugzilla.mozilla.org/attachment.cgi?id=$url";
    }

    print "<p class='url'>Review of <a href=\"$url\">$url</a></p>\n";

    $text = get($url);
    die "Could not retrieve URL: $url" unless defined $text;
} else {
# Read from stdin
    while(<>) {
        $text .= $_;
    }
}

########################################
# Check for CRLF
if ($text =~ /\r\n/) {
    print "<p class='warn'>This file contains Windows line-endings!</p>\n";
}

########################################
# Review it
my %review = Review::JST::review($text);
my %found_problems;

if (%review) {
    print "<table border='1'>\n";
    print "<tr><th>Error</th><th>At</th><th>Line</th></tr>\n";
    foreach my $file (sort keys %review) {
        print "<tr><td class='filename' colspan='3'>$file</td></tr>\n";
        foreach my $line_num (sort { $a <=> $b } keys %{$review{$file}}) {
	    my @line = @{$review{$file}{$line_num}};
	    $line[2] =~ s/</&lt;/g;
	    $line[2] =~ s/>/&gt;/g;
	    print "<tr><td class='problem'>$line[0]</td><td class='linenum'>$line_num</td><td class='line'><pre>+$line[2]</pre></td></tr>\n";
	    $found_problems{$line[0]}++;
        }
    }
    print "</table>\n";

    print "<h2>Error descriptions:</h2>\n";
    print "<pre>\n";
    foreach my $problem (sort keys %found_problems) {
        print "$problem (" . $found_problems{$problem} . "): $Review::JST::reasons{$problem}\n";
    }
    print "</pre>\n";
} else {
    print "<p class='congrats'>Congratulations! I found no coding problems in your patch. That does not mean that it is ready for check in though... you still need to pass something more intelligent than a script. :-)</p>";
}
