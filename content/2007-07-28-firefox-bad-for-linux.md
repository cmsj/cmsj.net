title: Firefox bad for Linux?
slug: firefox-bad-for-linux
date: 2007-07-28


Firefox is a very popular piece of software. Claims run up to 100 million users, which is really good and on the whole I think it's a very good browser.
However.
What Firefox isn't, is integrated. Sure it renders using gtk (and Cairo, if not already then soon) and gnome actions involving URLs spawn Firefox, but it's still trapped away in its own little universe - Marc Andreeson's gift to the world, a platform agnostic application architecture. Clearly Mozilla has built itself a highly capable cross-platform application architecture, but that necessarily isolates them on every platform.
The trigger behind this post is the patches that recently appeared to let Epiphany use Webkit (Apple's fork of KHTML, as used n Safari). Epiphany isn't a bad browser, but it's not flexible like the fox (purely because there aren't enough extensions). The problem here is that if GNOME is going to achieve the online desktop integration they have been talking about, reliable HTML widgets seem quite vital. GtkMozEmbed (I say having never used it) appears to be very painful to work with.
A high quality GNOME widget based on Webkit that makes displaying HTML really easy would be so extraordinarily useful to the project. It would allow the browser to disappear into the desktop - want to visit a page? click/press something to type some stuff which is an address or search keywords. Out slides the appropriate web page. It gets rid of the necessity to go Applications-&gt;Internet-&gt;Firefox before typing a URL (and yes I know things like deskbar can launch a browser in these circumstances). Mostly it massively lower the barrier to writing apps which partly rely on the internet, or HTML in general, which can only be a good thing for a more online world.
What's holding it back though is Firefox. It's a very popular piece of software, even on Windows. Maybe too popular, if Ubuntu were to drop Firefox by default in favour of an integrated future version of Epiphany it could hurt Ubuntu - one of its selling points is no longer that it uses the much vaunted Firefox thingy people have heard of.
(I also wonder if GTK should support CSS ;)
