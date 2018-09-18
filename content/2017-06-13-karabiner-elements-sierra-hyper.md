title: Hyper Key in macOS Sierra with Karabiner Elements
slug: karabiner-elements-sierra-hyper.md
date: 2017-06-13


Over the last few years, [various](http://brettterpstra.com/2012/12/08/a-useful-caps-lock-key/) [people](https://www.nadeau.tv/configure-hyper-key-osx/) have used [Karabiner](https://pqrs.org/osx/karabiner/) to remap Caps Lock to cmd+shift+opt+ctrl, which is such an unusual combination of modifier keys, that it effectively makes Caps behave as a completely new modifier (which we have collectively called "Hyper", in reference to old UNIX workstation keyboards).

And for a time, it was good.

Then came macOS Sierra, which changed enough of the input layers of its kernel, that Karabiner was unable to function. Thankfully, Karabiner's author, Fumihiko Takayama, began work on a complete rewrite of Karabiner, which is currently called [Karabiner Elements](https://github.com/tekezo/Karabiner-Elements).

Initially, Elements only supported very simple keyboard modifications - you could swap one key for another, but that was it. Various folk quickly got to work offering [quick hacks](https://github.com/tekezo/Karabiner-Elements/pull/170) to get a Hyper key to work, and others started to try to [work around](http://brettterpstra.com/2016/09/29/a-better-hyper-key-hack-for-sierra/) the missing support, with other tools.

I'm very glad to say that it is now possible to do a proper Hyper remap with Karabiner Elements (and to be clear, none of this is my work, all credit goes to Fumihiko).

Here's how you can get it:

 * Download and install [https://pqrs.org/latest/karabiner-elements-latest.dmg](https://pqrs.org/latest/karabiner-elements-latest.dmg)
 * Launch the Karabiner Elements app, go to the Misc tab and check which version you have, if it's less than 0.91.1, click either `Check for updates` or `Check for beta updates` until you get offered 0.91.1 or higher, then install that update and re-launch the Karabiner Elements app.
 * You probably want to remove the example entry in the Simple Modifications tab.
 * Edit `~/.config/karabiner/karabiner.json`
 * Find the `simple_modifications` section, and right after it, paste in:

```json
"complex_modifications": {
    "rules": [
        {
            "manipulators": [
                {
                    "description": "Change caps_lock to command+control+option+shift.",
                    "from": {
                        "key_code": "caps_lock",
                        "modifiers": {
                            "optional": [
                                "any"
                            ]
                        }
                    },
                    "to": [
                        {
                            "key_code": "left_shift",
                            "modifiers": [
                                "left_command",
                                "left_control",
                                "left_option"
                            ]
                        }
                    ],
                    "type": "basic"
                }
            ]
        }
    ]
},
```

 * As soon as you save the file, Elements will notice it has changed, and reload its config. You should immediately have a working Hyper key 😁

If you're not confident at your ability to hand-merge JSON like this, and don't need anything from Elements other than the basic defaults, plus Hyper, feel free to grab [my config](https://gist.githubusercontent.com/cmsj/23ca8a570c060e8ccb2a36cee70ed28b/raw/60cb590411193f24a56fb8f52f96093c5191ba22/karabiner.json) and drop it in `~/.config/karabiner/`.

*Supplemental note for High Sierra*

I've only tested this very briefly on High Sierra, but I had to disable SIP to get the Elements `.kext` to load. I'm not quite sure what's going on, but I reported it [on GitHub](https://github.com/tekezo/Karabiner-Elements/issues/777). (Note that you can re-enable SIP after the kext has been loaded successfully once)

*Update*

Many people like to turn Caps into Hyper, but also have it behave as Escape if it is tapped on its own. As of Karabiner Elements 0.91.3 [this appears](https://twitter.com/ttscoff/status/875029764377108480) to be possible by adding this to the manipulator:

```json
"to_if_alone": [
    {
        "key_code": "escape",
        "modifiers": {
            "optional": [
                "any"
            ]
        }
    }
],
```

(thanks to [Brett Terpstra](http://brettterpstra.com/) for the sample of this