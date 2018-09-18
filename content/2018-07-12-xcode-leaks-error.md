title: Fixing an error in Xcode Instruments's Leaks profile
slug: xcode-leaks-error
date: 2018-07-12


As part of our general effort to try and raise the quality of Hammerspoon, I've been working with [@latenitefilms](https://twitter.com/latenitefilms) to track down some memory leaks, which can be very easy if you use the Leaks profile in Xcode's "Instruments" tool. I tried this various ways, but I kept running into this error:

![Screenshot]({{ "/assets/2018-07-12-xcode-leaks-error.png" | absolute_url }})

After asking on the [Apple Developer Forums](https://forums.developer.apple.com/thread/104011) we got an interesting response from an Apple employee that code signing might be involved. One change later to not do codesigning on Profile builds and Leaks is working again!

So there we go, if you see "An error occurred trying to capture Leaks data" and "Unable to acquire required task port", one thing to check is your code signing setup. I don't know what specifically was wrong, but it's easy enough to just not sign local debug/profile builds most of the time anyway.
