package Review::JST;

use strict;

%Review::JST::reasons =
    ( A => "String arguments to functions should be declared as nsAString.",
      B => "Do not compare == PR_TRUE or PR_FALSE.  Use (x) or (!x) instead.  == PR_TRUE, in fact, is *different* from if (x)!",
      E => "You are using str.Length() == 0 instead of str.IsEmpty().",
      F => "You put an else right after a return.  Delete the else, it's useless and causes some compilers to choke.",
      L => "The line was more than 80 characters long.",
      N => "You used new without checking the return value for null.",
      P => "You left a debug printf() lying around.",
      O => "Operators should be at the end of the line, not the beginning.",
      Q => "You used QueryInterface--use CallQueryInterface or do_QueryInterface instead.",
      R => "nsresult should be declared as rv.  Not res, not result, not foo.  rv.",
      S => "You should use NS_LITERAL_STRING(\"...\") instead of NS_ConvertASCIItoUCS2(\"...\"), AssignWithConversion(\"...\"), EqualsWithConversion(\"...\"), and nsAutoString()",
      T => "You used do_QueryInterface(this)--You should just NS_ADDREF() directly.",
      X => "You left lines around with XXX on them.  This may not be a problem, just check it.",
      W => "There is extra whitespace at the end of the line, tabs on the line, or no space after ',', if, while, for or switch",
      "{" => "Methods should always have the opening brace on their own line.",
      "!" => "You compared a pointer with nsnull instead of using !myPtr or (myPtr)"
    );

sub review {
    my ($text) = @_;
    
    # The current line number in the patch
    my $patch_line_num = 0;
    # The file the patch refers to currently
    my $file_name;
    # The current line number of the actual line in the file
    my $line_num;

    #
    # State variables for parsing the code
    #
    # whether we're in various types of comment
    my ($ifdef_comment, $slashstar_comment) = (0, 0);
    # whether we're in parentheses
    my $parens = 0;
    # name of the variable that was recently new'd
    my $newed_varname;
    # line number and line on which variable was new'd
    my ($newed_line, $newed_line_num, $newed_patch_line_num);
    # else-after-return state (0=none, 1=found return, 2=return ...; 3=return ...; }
    my $else_return_lev = 0;


    my %review;

    foreach (split /\r?\n/, $text) {
	$patch_line_num++;
	# Get the filename
	if(/^\+\+\+ ([^\s]+).+$/) {
	    if($newed_varname) {
		$newed_varname = '';
		$review{$file_name}{$newed_line_num} =
		    [ "N", $newed_patch_line_num, $newed_line ];
	    }

	    $file_name = $1;
	    chomp $file_name;

	# Get the current line number if we run across a new hunk
	} elsif(/^\@\@ \-(\d+),(\d+) \+(\d+),(\d+) \@\@/) {
	    $line_num = $3;
	    if($newed_varname) {
		$newed_varname = '';
		$review{$file_name}{$newed_line_num} =
		    [ "N", $newed_patch_line_num, $newed_line ];
	    }

	    # Reset the parsing stuff 'cause we don't know what's here
	    $parens = 0;
	    ($ifdef_comment, $slashstar_comment) = (0, 0);
	    $newed_varname = "";

	# Increment the line number if this line remained the same
	} elsif(/^\s/) {
	    $line_num++;

	    # Get rid of leading +
	    $_ = substr($_,1);

	    # Check for ifdef comments
	    if((/^#if/ && /DEBUG/) || /^#if 0/) {
		$ifdef_comment++;
	    } elsif(/^#endif/ && $ifdef_comment) {
		    $ifdef_comment--;
		}

	       # Check for open parens and /* comments
	       if(!$ifdef_comment) {
		   for(my $i = 0; $i<length($_); $i++) {
		       if(!$slashstar_comment && substr($_, $i, 1) eq "(") {
			   $parens++;
		       } elsif(!$slashstar_comment && substr($_, $i, 1) eq ")") {
			   if($parens > 0) {
			       $parens--;
			   }
		       } elsif(substr($_, $i, 2) eq "/*") {
			   $slashstar_comment = 1;
		       } elsif(substr($_, $i, 2) eq "*/") {
			   $slashstar_comment = 0;
			   # Don't look for stuff anymore 
		       } elsif(substr($_, $i, 1) eq "//") {
			   last;
		       }
		   }
	       }

	       # Check for code stuff (commented out doesn't count)
	       if(!$slashstar_comment && !/^\s*\/\//) {
		   # Check for a null check of the new'd variable
		   if($newed_varname &&
		      ((/\bif\b/
			&& (/\((\s|\*)*$newed_varname\s*\)/
			    || /\!(\s|\*)*$newed_varname\b/
			    || /\b(\*)*$newed_varname\s*[!=]=\s*(0|nsnull)/
			    || /(0|nsnull)\s*[!=]=(\s|\*)*$newed_varname\b/))
		       || /NS_ENSURE_STATE\(\s*$newed_varname\s*\)/
		       || /NS_ENSURE_TRUE\(\s*$newed_varname\s*,.+\)/)
		      )
		   {
		       $newed_varname = "";
		   }

		   # Check for else-after-return
		   my $else_check = $_;
		   if ($else_return_lev == 0) {
		       if ($else_check =~ /\breturn(.*)/) {
			   $else_check = $1;
			   $else_return_lev = 1;
		       }
		   }
		   if ($else_return_lev == 1) {
		       if ($else_check =~ /^[^;]*;(.*)/) {
			   $else_check = $1;
			   $else_return_lev = 2;
		       }
		   }
		   if ($else_return_lev == 2) {
		       if ($else_check =~ /^\s*}(.*)/) {
		       $else_check = $1;
		       $else_return_lev = 3;
		   }
	       }
	       if ($else_return_lev >= 2) {
		   if ($else_check =~ /^\s*else/) {
		       $else_return_lev = 0;
		   } elsif ($else_check !~ /^\s*$/) {
		       $else_return_lev = 0;
		   }
	       }
	   }

        # Check for errors in the actual patch
	} elsif(/^\+/ && !/^\+\+\+ /) {
	    # Get rid of leading +
	    $_ = substr($_,1);

	    # Check for ifdef comments
	    if((/^#if/ && /DEBUG/) || /^#if 0/) {
		$ifdef_comment++;
	    } elsif(/^#endif/ && $ifdef_comment) {
		    $ifdef_comment--;
		}

	       # Problem Type (if problem found)
	       my $problem;

	       # Check for open parens, non-nsAString args, and /* comments
	       if(!$ifdef_comment) {
		   for(my $i = 0; $i<length($_); $i++) {
		       if(!$slashstar_comment && substr($_, $i, 1) eq "(") {
			   $parens++;
		       } elsif(!$slashstar_comment && substr($_, $i, 1) eq ")") {
			   $parens--;
		       } elsif(substr($_, $i, 2) eq "/*") {
			   $slashstar_comment = 1;
		       } elsif(substr($_, $i, 2) eq "*/") {
			   $slashstar_comment = 0;
			   # Don't look for stuff anymore 
		       } elsif(substr($_, $i, 1) eq "//") {
			   last;
			   # Verify that ns*String is always nsA*String in parens
		       } elsif($parens && substr($_, $i) =~ /\b(ns[:alpha:]*String)(?!\s*\()/) {
			   if(substr($1, 3, 1) ne "A" || substr($1, 4, 1)  !~ /[A-Z]/) {
			       $problem = "A";
			   }
		       }
		   }
	       }

	       # Check for code stuff (commented out doesn't count)
	       if(!$slashstar_comment && !/^\s*\/\//) {
		   # Check for a null check of the new'd variable
		   if($newed_varname &&
		      ((/\bif\b/
			&& (/\((\s|\*)*$newed_varname\s*\)/
			    || /\!(\s|\*)*$newed_varname\b/
			    || /\b(\*)*$newed_varname\s*[!=]=\s*(0|nsnull)/
			    || /(0|nsnull)\s*[!=]=(\s|\*)*$newed_varname\b/))
		       || /NS_ENSURE_STATE\(\s*$newed_varname\s*\)/)
		      )
		   {
		       $newed_varname = "";
		   }

		   # Check for else-after-return
		   my $else_check = $_;
		   if ($else_return_lev == 0) {
		       if ($else_check =~ /\breturn(.*)/) {
			   $else_check = $1;
			   $else_return_lev = 1;
		       }
		   }
		   if ($else_return_lev == 1) {
		       if ($else_check =~ /^[^;]*;(.*)/) {
			   $else_check = $1;
			   $else_return_lev = 2;
		       }
		   }
		   if ($else_return_lev == 2) {
		       if ($else_check =~ /^\s*}(.*)/) {
		       $else_check = $1;
		       $else_return_lev = 3;
		   }
	       }
	       if ($else_return_lev >= 2) {
		   if ($else_check =~ /^\s*else/) {
		       $problem = "F";
		       $else_return_lev = 0;
		   } elsif ($else_check !~ /^\s*$/) {
		       $else_return_lev = 0;
		   }
	       }


	       # Check for dangling printfs (it's OK inside #ifdef)
	       if(!$ifdef_comment && /\bprintf\b/) {
		   $problem = "P";
	       }
	       # Check for == nsnull or != nsnull (bad)
	       elsif(/[!=]=\s*nsnull\b/ || /\bnsnull\s*[!=]=/) {
		   $problem = "!";
	       }
	       # Check for == PR_TRUE or != PR_TRUE (bad)
	       elsif(/[!=]=\s*(PR_TRUE|PR_FALSE)\b/ || /\b(PR_TRUE|PR_FALSE)\s*[!=]=/) {
		   $problem = "B";
	       }
	       # Check for str.Length() == 0 (should be IsEmpty())
	       elsif(/\S*(\.|->)Length\(\)\s*(==|>|\!=)\s*0/
		     || /0\s*(==|<|\!=)\s*\S*(\.|->)Length\(\)/
		     || /\S*(\.|->)Length\(\)\s*>=\s*1/
		     || /1\s*<=\s*\S*(\.|->)Length\(\)/) {
		   $problem = "E";
	       }
	       # Check for NS_ConvertASCIItoUCS2("...")
	       elsif(/\b(Assign|Equals|Append)WithConversion\(".*"\)/
		     || /\bNS_ConvertASCIItoUCS2\(".*"\)/
		     || /\bnsAutoString\s*\(\s*\)/) {
		   $problem = "S";
	       }
	       # Check for do_QueryInterface(this)
	       elsif(/\bdo_QueryInterface\( *this *\)/) {
		   $problem = "T";
	       }
	       # Check for method declaration brace on its own line
	       elsif(/^\w.*\)\s*\{/) {
		   $problem = "{";
	       }
	       # Check for initializing nsCOMPtr< with ( instead of =
	       #elsif(/\bnsCOMPtr<.*>\s*\w+\s*\(/) {
	       #       $problem = "I"
	       #}
	       # Check for space after if, while, for and switch
	       elsif(!/^\#/ && /\b(\,|if|while|for|switch)(\s*)\(/ && $2 ne " ") {
		   $problem = "W";
	       }
	       # Verify that ){ does not occur
	       elsif(/\)(\s*)\{/ && $1 ne " ") {
		   $problem = "W";
	       }
	       # Check for QueryInterface (use CallQueryInterface instead)
	       elsif(/(->|\.)\s*QueryInterface\b/) {
		   $problem = "Q";
	       }
	       # Check for nsresults with crappy names
	       elsif(/\bnsresult\s+(\w+)\s*(;|=)/ && $1 ne "rv") {
		   $problem = "R";
	       }
	       # Check for variable use before null check
	       elsif($newed_varname && /\b$newed_varname\b/) {
		   $newed_varname = "";
		   $problem = "N";
	       }
	       # Check for operator at beginning of line
	       elsif(/^\s*[?:,&|\^+\-\/]/ && !/^\s*(--|\+\+|\/[*\/])/) {
		   $problem = "O";
	       }

	       # Check for new variable
	       if(/((\w|-|>)+)\s*=\s*new\b/) {
		   $newed_varname = $1;
		   $newed_line_num = $line_num;
		   $newed_patch_line_num = $patch_line_num;
		   $newed_line = $_;
	       }
	   }

	    # Check for non-code stuff
	    if(!$problem) {
		# Check for long line length
		if(length($_) > 80) {
		    $problem = "L";
		}
		# Check for lines with XXX
		elsif(/XXX/) {
		    $problem = "X";
		}
		# Check for spaces at the end of the line
		elsif(/\s$/ && /\S/ && !/Contributor\(s\):/) {
		    $problem = "W";
		}
		# Check for tabs
		elsif($file_name !~ /Makefile.in$/
		      && $file_name !~ /makefile.win$/
		      && /\t/) {
		    $problem = "W";
		}
	    }

	    if($problem) {
		if($problem eq "N") {
		    $review{$file_name}{$newed_line_num} =
			[ "N", $newed_patch_line_num, $newed_line ];
		} else {
		    $review{$file_name}{$line_num} =
			[ $problem, $patch_line_num, $_ ];
		}
	    }
	    $line_num++;
	}
    }

    if($newed_varname) {
	$newed_varname = '';
	$review{$file_name}{$newed_line_num} =
	    [ "N", $newed_patch_line_num, $newed_line ];
    }

    return %review;
}

1
