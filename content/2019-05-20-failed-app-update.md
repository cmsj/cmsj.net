title: Update: Failing to create an app
slug: app-creation-failed-update1
date: 2019-05-20


[Previously](/2019/04/24/app-creation-failed.html) I wrote about how I'd tried to create an app, but ultimately failed because I wasn't getting the results I wanted out of the macOS CoreAudio APIs.

Thanks to some excellent input from [David Lublin](https://twitter.com/DavidLublin) I refactored the code to be able to switch easily between different backend audio APIs, and [implemented a replacement](https://github.com/cmsj/HotMic/blob/master/HotMic/Audio%20Backends/THMBackEndAVFCapture.m) for CoreAudio using AVFoundation's AVCaptureSession and it seems to work!

I'd still like to settle back on CoreAudio at some point, but for now I can rest assured that whenever the older versions of SoundSource stop working, I still have a working option.
