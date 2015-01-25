// ==UserScript==
// @name          BugZilla JST Review link
// @namespace     http://beaufour.dk/2006/jst-review
// @description	  Adds a "Do JST review" link to patches on Bugzilla
// @include       https://bugzilla.mozilla.org/show_bug.cgi?id=*
// ==/UserScript==

const debug = 0;

function logit(msg)
{
    if (debug) 
	GM_log(msg);
}

logit("script start");
// Wouldn't it be wonderful if there were ids on bugzilla's tables?
var table = document.getElementsByTagName('table')[7];

var atts = table.rows;
if (!atts) {
    return logit("Could not find attachments table?!");
}
logit('got ' + atts.length + ' attachments');
for (var i = 1; i < atts.length; ++i) {
    var c = atts.item(i).cells;
    if (/patch/.test(c.item(1).textContent)) {
	var href = c.item(0).firstChild.nextSibling.href;
	var atid = /id=(\d+)$/.exec(href)[1];
	var newlink = document.createElement("a");
	newlink.href = "http://beaufour.dk/jst-review/?patch=" + atid;
	var img = document.createElement("img");
	img.src = "http://beaufour.dk/jst-review/jst.jpg";
	img.width = 27;
	img.height = 17;
	img.alt = "Do JST Review";
	img.border = "0";
	newlink.appendChild(img);
	c.item(0).appendChild(newlink);
    }
}
logit("script end");
