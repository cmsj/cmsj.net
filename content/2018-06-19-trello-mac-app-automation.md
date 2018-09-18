title: A little bit of automation of the Trello Mac App
slug: trello-mac-app-automation
date: 2018-06-19


[Trello](https://www.trello.com) have a Mac app, which I use for work and it struck me this morning that several recurring calendar events I have, which exist to remind me to review a particular board, would be much more pleasant if they contained a link that would open the board directly.

That would be easy if I used the Trello website, but I quite like the app (even though it's really just a browser pretending to be an app), so I went spelunking.

To cut a long story short, the Trello Mac app registers itself as a handler for `trello://` URLs, so if you take any `trello.com` board URL and replace the `https://` part with `trello://` you can use it as a link in your calendar (or anywhere else) and it will open the board in the app.
