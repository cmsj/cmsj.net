title: Getting battery data from AirPods in macOS
slug: airpod-battery-ear-data.md
date: 2017-11-27


A recent [feature request](https://github.com/Hammerspoon/hammerspoon/issues/1608) for [Hammerspoon](http://www.hammerspoon.org) requested that we add support for reading battery information about AirPods ([UK](http://amzn.to/2zxsZSt) [US](http://amzn.to/2zxl2wn)).

Unfortunately because their battery status is quite complex (two earbuds and the case), this information is not reported via the normal IOKit APIs, but with a bit of poking around in the results of [class-dump](http://stevenygard.com/projects/class-dump/) for macOS High Sierra I was able to find some relevant methods/properties on [IOBluetoothDevice](https://developer.apple.com/documentation/iobluetooth/iobluetoothdevice) that let you read information about the battery level of individual AirPods and the case, plus determine which of the buds are currently in an ear!

So, the next release of Hammerspoon should include [this code](https://github.com/Hammerspoon/hammerspoon/commit/e5738e8231b90b0506bbacf62cef6491364c5c22) to expose all of this information neatly via `hs.battery.privateBluetoothBatteryInfo()` 😁