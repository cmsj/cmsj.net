title: LCD and a crazy disk chassis
slug: lcd-and-crazy-disk-chassis
date: 2013-02-06


If you saw my [recent post](http://www.tenshu.net/2013/01/funky-lcd4linux-python-module.html) on some preparatory work I'd been doing for the arrival of an LCD status panel for my HP Microserver, it's probably no surprise that there is now a post talking about its arrival :)

Rather than just waste the 5.25" bay behind the LCD, I wanted to try and put some storage in there, particularly since the Microserver's BIOS can be [modified](http://www.avforums.com/forums/networking-nas/1521657-hp-n36l-microserver-updated-ahci-bios-support.html) to enable full AHCI on the 5th SATA port.

I recently came across the Icy Box [IB-RD2121StS](http://www.raidsonic.de/en/products/ssd.php?we_objectID=8206), a hilarious piece of hardware. It's the size and shape of a normal 3.5" SATA disk, but the back opens up to take two 2.5" SATA disks. These disks can then be exposed either individually, or as a combined RAID volume (levels 0 or 1). Since I happen to have a couple of 1TB 2.5" disks going spare, this seemed like the perfect option, as well as being so crazy that I couldn't not buy it!

The LCD is a red-on-black pre-made 5.25" bay insert from [LCDModKit](http://www.lcdmodkit.com/). It has an [LCD2USB](http://www.harbaum.org/till/lcd2usb/index.shtml) controller, which means it's very well supported by projects like [lcd4linux](http://ssl.bulix.org/projects/lcd4linux/) and [lcdproc](http://www.lcdproc.org/). It comes with an internal USB connector (intended to connect directly to a motherboard LCD port), except the Microserver's internal USB port is a regular external Type A port. Fortunately converters are easy to come by.

Something I hadn't properly accounted for in my earlier simulator work is that the real hardware only has space for 8 user-definable characters and I was using way more than that (three of my own custom icons, but lcd4linux's split bars and hollow graphs use custom characters too). Rather than curtail my own custom icons, I chose to stop using hollow graphs, which seems to have worked.

![Icy Box enclosure]({static}/IMG_5588.jpg)
*The Icy Box enclosure*

![Ta-da! The back opens up]({static}/IMG_5592.jpg)
*Ta-da! The back opens up*

![Selector switch]({static}/IMG_5590.jpg)
*Selector switch for which type of volume/RAID you want*

![Icy Box and LCD]({static}/IMG_5598.jpg)
*Marrying the Icy Box and the LCD. Only a small amount of metalwork required*

![Box and LCD installed]({static}/IMG_5600.jpg)
*Icy Box and LCD being installed*

![Finished installed]({static}/IMG_5606.jpg)
*Finished install!*

