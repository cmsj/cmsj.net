title: More PS3 video stuff
slug: more-ps3-video-stuff
date: 2007-06-09


I came across a python script called [vepp](http://can.homeunix.org/sw/vepp/), which aims to be a simple way of transcoding files for portable media devices. Why not also use it for very unportable media devices such as the PS3? :)
Initially I've just added a target for fairly high bitrate 720p H.264/AVC, 1080 and MPG-SP targets still to come.
If you want to track my development version, you can do so [via Launchpad](https://code.launchpad.net/~cmsj/+junk/ps3tools). You will need to use [bzr](http://www.bazaar-vcs.org) thus: bzr branch http://bazaar.launchpad.net/~cmsj/+junk/ps3tools
You'll need a capable version of ffmpeg, as discussed [previously](http://www.tenshu.net/archives/2007/06/03/transcoding-video-for-the-ps3-in-ubuntu/). Output files will be written to the current directory (I'm looking at adapting the current behaviour to be able to automatically direct the output to either attached media that is PS3 compatible (CF/SD/MS/USB) or sending it straight to a directory you are [sharing via UPnP](http://mediatomb.cc/) (far more useful than ferrying things about with SD cards!)
Here is my current patch against vepp:
`=== modified file 'vepp-2.0.1.py' (properties changed)--- vepp-2.0.1.py       2007-06-09 01:01:48 +0000+++ vepp-2.0.1.py       2007-06-09 03:12:21 +0000@@ -4,8 +4,8 @@ from math import sqrt # defaults-remove = True-target = 'psp-oe'+remove = False+target = 'ps3-avc-720p' vbr = True audio = None@@ -85,6 +85,22 @@         'qmax': 24,         'channels': (2, 1),         },+    'ps3-avc-720p': { # Only tested with firmware 1.80+        'maxx': 1280,+        'maxy': 720,+        'stepx': 8, # FIXME: lower?+        'stepy': 8, # FIXME: lower?+        'pixels': 1280 * 720,+        'namedfiles': True,+        'thumb': False, # FIXME: Can this be True?+        'ext': "mp4",+        'video': ["-vcodec", "h264", "-f", "mp4", "-bufsize", "14000k", "-maxrate", "14000k", "-coder", "1", "-level", "31", "-r", "24000/1001", "-g", "300"],+        'audio': ["-acodec", "aac", "-ab", "160k"],+        'bitrate': lambda x,y: "3072000",+        'qscale': 18,+        'qmax': 24,+        'channels': (2, 1),+        },     's60': {         'maxx': 352,         'maxy': 288,`
It would be nice to be able to push content to the PS3 from a LAN, but I have no idea how they could do it sanely. Maybe I can push files via Bluetooth.
Of course, if the rumours are true, this is going to all be immaterial shortly...
