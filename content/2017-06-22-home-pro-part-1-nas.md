title: Home networking like a pro - Part 1 - Network Storage
slug: home-pro-part-1-nas.md
date: 2017-06-22


## Introduction

This is part one in a series of posts about some hardware I recommend (or otherwise!) for people who want to bring some semi-professional flair to their home network.

The first topic is storage - specifically, Network Attached Storage.

## Background

For the last few years, I was running a Mac Mini with two 3TB drives in a RAID1 array in a LaCie 2big Thunderbolt chassis ([US](https://www.amazon.com/gp/product/B00KQD0HM2/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B00KQD0HM2&linkCode=as2&tag=cmsj-20&linkId=263d4ed10fb9c73f39e787d9266f3851) [UK](https://www.amazon.co.uk/gp/product/B00KYFU5YM/ref=as_li_tl?ie=UTF8&camp=1634&creative=6738&creativeASIN=B00KYFU5YM&linkCode=as2&tag=cmsj-21&linkId=9290f58318a0bfd748de49c6e53c8f2c)), with the Mac running macOS Server to provide file sharing (AFP and SMB), and Time Machine backups for the rest of the network.

This was a very nice solution, in that the Mac was a regular computer, so I could make it do whatever I wanted, but it did have the drawbacks that the Thunderbolt chassis only had two drive bays, and I had trouble getting the Mac to run reliably for months at a time (I ran into GPU related kernel panics, perhaps because it was attached to a TV rather than a monitor).

Around the time I was selecting the Mac/LaCie, most NAS devices in a similar price range were very underpowered ARM devices, and could do little more than share files, but in 2017 almost all NAS devices are much more powerful x86 devices that often have extensive featuresets (e.g. running containers, VMs, hardware accelerated video transcoding, etc.) so I decided it was time to switch.

## Solution

I ended up choosing a Synology DS916+ ([US](https://www.amazon.com/gp/product/B01EMZHLZU/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B01EMZHLZU&linkCode=as2&tag=cmsj-20&linkId=4bc9ac2f2590480e49aef6993329eb39) [UK](https://www.amazon.co.uk/gp/product/B01EMZHLZU/ref=as_li_tl?ie=UTF8&camp=1634&creative=6738&creativeASIN=B01EMZHLZU&linkCode=as2&tag=cmsj-21&linkId=a5a66e7532a51fb5478e07202daa05d2)), popped one of the 3TB drives (Western Digital Red ([US](https://www.amazon.com/gp/product/B008JJLW4M/ref=as_li_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=B008JJLW4M&linkCode=as2&tag=cmsj-20&linkId=d2d3d7db9bcd9bdf879a213d405a343b) [UK](https://www.amazon.co.uk/gp/product/B008JJLW4M/ref=as_li_tl?ie=UTF8&camp=1634&creative=6738&creativeASIN=B008JJLW4M&linkCode=as2&tag=cmsj-21&linkId=c644f89fe12d6b3d39794ca77b65cb9a))) out of the LaCie and into the Synology, and set about migrating my data over. I then moved the other drive, and put in two more 3TB drives, all of which are running as a single Synology Hybrid RAID volume with a BTRFS filesystem (note that the Hybrid RAID really seems to just be RAID5).

I configured the Synology to serve files over both AFP and SMB, and enabled its support for Time Machine via AFP. I was also able to connect both of its Ethernet ports to my switch (a ZyXEL GS1900 24 port switch, which I will cover in an upcoming post) and enabled LACP on each end to bond the two connections into a single 2Gb link.

So, how did it work out?

The AFP file sharing is great, and works flawlessly. SMB is a little more complex, because recent versions of macOS tend to enforce encryption on SMB connections, which makes them go much slower, but this [can be disabled](https://dpron.com/os-x-10-11-5-slow-smb/). I tested Time Machine over SMB, which is officially supported by Synology, but is a very recent addition, and it proved to be unreliable, so that is staying on AFP for now.

Something I was particularly keen on, with the Synology, was that it has an "app store" and one of the available applications is Docker. I was running a few UNIX daemons on the Mac Mini which I wanted to keep, and Docker containers would be perfect for them, however, I discovered that the version of Docker provided by Synology is pretty old and I ran into a strange bug that would cause dockerd to consume all available CPU cycles.

For now, the containers are running on an Intel NUC (which will also be covered in an upcoming post) and the Synology is focussed on file sharing.

## Open Source

Synology's NAS products are based on Linux, Samba, netatalk and a variety of other Open Source projects, with their custom management GUI on top. They do [publish source](https://sourceforge.net/projects/dsgpl/files/Synology%20NAS%20GPL%20Source/), but it's usually a little slow to arrive on the site, and it's not particularly easy (or in some cases even possible) to rebuild in a way that lets you actively customise the device.

## Conclusion

Overall, I like the Synology, but I think if I'd known about the Docker issue, I might have built my own machine and put something like [FreeNAS](http://www.freenas.org/) on it. More work, less support, but more flexibility.

The recent 5-8 drive Synologies now support running VMs, which seems like a very interesting prospect, since it ought to isolate you from Synology's choices of software versions.