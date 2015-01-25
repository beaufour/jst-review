#!/usr/bin/perl -T -I.

use strict;
use CGI;
use Review::JST;

my $p = new CGI;

print $p->header;
print <<EOM;
<HTML>
<HEAD>
<TITLE>JST Reviewer Simulacrum</TITLE>
<STYLE>
table {
        background-color: #FFFFDD
}
.found_reason {
        font-weight: bold
}
</STYLE>
</HEAD>
<BODY>
<CENTER><H2>JST Review Simulacrum</H2></CENTER>
EOM

my %review;
if($p->param("patch_file")) {
        my $text;
        {
                no strict;
                my $fh = $p->param("patch_file");
                while(<$fh>) {
                        $text .= $_;
                }
        }
        %review = Review::JST::review($text);
} elsif($p->param("patch_url")) {
        my $url = $p->param("patch_url");
        $ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
        open(URLFILE, "-|") or exec("wget", "-q", "-O", "-", $url);
        my $text;
        while(<URLFILE>) {
                $text .= $_;
        }
        close URLFILE;
        %review = Review::JST::review($text);
} elsif($p->param("patch_text")) {
        %review = Review::JST::review($p->param("patch_text"));
} else {
        print <<EOM;
<P>Post your unified diff here, and the JST Review Simulacrum will pick
it apart just like JST would.  Well, approximately.  It at least does
what JST would probably do if he were (for example) reviewing a patch
while on a three-week vacation in Europe.  If this situation ever arises
(as we are sure it will not), come here to get your JST review fix.</P>

<P>If you're looking for source (or a command-line version),
<A HREF="http://www.johnkeiser.com/jst-review.tar.gz">look here.</A>
Instructions: untar.  Run <CODE>./jst-review.pl mypatch.patch</CODE>.</P>

<FORM METHOD=post ENCTYPE=multipart/form-data NAME=mainform onSubmit='if(this.patch_file.value == "") { this.enctype = null; this.method = "GET"; }'>
<INPUT TYPE=submit VALUE="Review Patch"><BR><BR>
You can upload your patch here:<BR>
<INPUT TYPE=FILE NAME=patch_file><BR><BR>
Or type the URL to your patch here:<BR>
<INPUT TYPE=TEXT SIZE=80 NAME=patch_url><BR><BR>
Or you can paste it here:<BR>
<TEXTAREA NAME=patch_text ROWS=10 COLS=81>
</TEXTAREA><BR>
Select which types of error you want to see here:<BR>
EOM

print "<SELECT MULTIPLE SIZE=" . scalar(keys %Review::JST::reasons) . " NAME=reason_type>\n";
foreach my $problem (sort keys %Review::JST::reasons) {
        print "<OPTION SELECTED VALUE='$problem'>$problem - " . $Review::JST::reasons{$problem} . "</OPTION>\n";
}

print <<EOM;
</SELECT>
</FORM>
EOM
}

if($p->param("patch_file") || $p->param("patch_url") || $p->param("patch_text")) {
        print <<EOM;
<P>Below are the listed problems with your patch.  It shows the error code, line # and the actual line.
Click on the error code to see the key of what the error means.</P>
EOM
        my @errors_to_show = $p->param("reason_type");

        #
        # Print the key
        #
        my %problems;
        foreach my $file (sort keys %review) {
                foreach my $line_num (sort keys %{$review{$file}}) {
                        $problems{$review{$file}{$line_num}[0]}++;
                }
        }

        print "<H2>Key</H2>\n";
        print "<TABLE BORDER=1>\n";
        print "<TR><TH>Key</TH><TH>Found</TH><TH>Explanation</TH></TR>\n";
        foreach my $problem (sort keys %Review::JST::reasons) {
                if(grep { $_ eq $problem } @errors_to_show) {
                        my $color = $problems{$problem} ? " CLASS=found_reason" : "";
                        print "<TR$color><TD$color><A NAME='$problem'>$problem</A></TD><TD>" . ($problems{$problem} ? $problems{$problem} : "&nbsp;") . "<TD$color>" . $Review::JST::reasons{$problem} . "</TD></TR>\n";
                }
        }
        print "</TABLE>\n";

        if(keys %review) {

                #
                # Print the problems discovered
                #
                print "<H2>Problems</H2>\n";
                print "<TABLE BORDER=1 BGCOLOR=#FFFFDD>\n";
                foreach my $file (sort keys %review) {
                        my $printed_file = 0;
                        foreach my $line_num (sort { $a <=> $b } keys %{$review{$file}}) {
                                my @line = @{$review{$file}{$line_num}};
                                if(grep { $_ eq $line[0] } @errors_to_show) {
                                        if(!$printed_file) {
                                                print "<TR><TH COLSPAN=3 ALIGN=left><FONT SIZE=+1>$file</FONT></TH></TR>\n";
                                                $printed_file = 1;
                                        }
                                        my $line_text = $line[2];
                                        $line_text =~ s/&/&amp;/g;
                                        $line_text =~ s/</&lt;/g;
                                        $line_text =~ s/>/&gt;/g;
                                        $line_text =~ s/ /&nbsp;/g;
                                        print "<TR><TD><A HREF='#" . $line[0] . "'>$line[0]</A></TD><TD><CODE>$line_num</CODE></TD><TD><CODE>$line_text</CODE></TD></TR>\n";
                                }
                        }
                }
                print "</TABLE>\n";
        } else {
                print "<H2>Congratulations!  Your patch has no problems!  r=jst-review.pl <SUP><A HREF='#disclaimer'>*</A></SUP></H2>\n";
        }
}

print <<EOM;
<P>
<A NAME="#disclaimer"><ADDRESS><SUP>*</SUP> This product is meant as an educational tool and aid to
development.  It has not received an official endorsement to perform an actual <CODE>r=</CODE> by
<CODE>jst</CODE>.  Anyone using it as such will have to answer to him.  It will not be pretty.  The
author shudders at the potentially gargantuan non-prettiness of this event.  We may even go so far
as to call it ugly.  If you do this, the author will probably not want to stand near you or any of
your loved ones for at least a 72-hour cooling-off period.</ADDRESS></A>

<P>Other problems this script does not address but JST just might put you in the corner for:<BR>
<UL>
<LI>private methods and protected methods that will not be overridden should not be declared
virtual or declared with NS_IMETHOD/NS_IMETHODIMP.  Use nsresult instead.</LI>
<LI>Use the block style of the file you are in when defining methods (implementations).  This
includes inline blocks.</LI>
<LI>Don't bother checking the return value of QueryInterface/CallQueryInterface.  Check whether
the result was <CODE>nsnull</CODE> instead.</LI>
</UL>
</P>

<P><A HREF="mailto:jkeiser\@iname.com">jkeiser\@iname.com</A> is the guy you should yell at if this don't work for you or if the grammar ain't quite correct.  Thanks go to <A HREF="mailto:sicking\@bigfoot.com">sicking\@bigfoot.com</A> as well.  Copyleft 2001.</P>
</BODY>
</HTML>
EOM
