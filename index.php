<? print '<?xml version="1.0" encoding="utf-8"?>'; ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>JST Review v2</title>
    <link href="default.css" rel="stylesheet" type="text/css"/>
  </head>
  <body>
<?
$cmd = "./jst-review2.pl ";
if ($_GET['patch']) {
  $cmd .= $_GET['patch'];
  print `$cmd`;
} else if ($_FILES['file'] && $_FILES['file']['tmp_name']) {
  $cmd .= "< " . $_FILES['file']['tmp_name'];
  print `$cmd`;
} else {
?>
<h1>JST Review v2</h1>
<form method="post"  enctype="multipart/form-data" action="."
      onsubmit='if (this.file.value == "") { this.enctype = null; this.method = "get"; }'>
     URI or attachment #: <input name="patch"/><br/>
     Upload file: <input type="file" name="file"/><br/>
     <input type="submit" value="Do review"/>
</form>
<p>
<a href="jst.user.js">greasemonkey script adding "jst" icon for patches on
bugzilla</a>
</p>

<h2>What Is This?</h2>
<p>
  This script will run through your patch and show common errors...
</p>

<h2>About This Version</h2>
<p>
This is, for now, just a copy of the original <a
href="http://www.johnkeiser.com/cgi-bin/jst-review-cgi.pl">JST Review
Simulacrum</a>, with a GreaseMonkey script and an ability to use attachment
numbers directly.
</p>

<h2>Todo list</h2>
<ul>
     <li>fix O-problem</li>
     <li>only check file types: .cpp, .h, and .idl</li>
     <li>choose problem types to show</li>
     <li>check function arguments (start with 'a', */& next to name)</li>
     <li>disable most checks inside comments (!= nsnull...)</li>
     <li>parameter to return content as csv</li>
     <li>allow multiple problems pr. line</li>
     <li>"compile-error output" formatting</li>
</ul>

<?
}
?>
  </body>
</html>
