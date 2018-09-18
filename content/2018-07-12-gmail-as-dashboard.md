title: Abusing Gmail as a ghetto dashboard
slug: gmail-as-dashboard.md
date: 2018-07-12


I'm sure many of us receive regular emails from the same source - by which I mean things like a daily status email from a backup system, or a weekly newsletter from a blogger/journalist we like, etc.

These are a great way of getting notified or kept up to date, but every one of these you receive is also a piece of work you need to do, to keep your Inbox under control. Gmail has a lot of powerful filtering primitives, but as far as I am able to tell, none of them let you manage this kind of email without compromise.

My ideal scenario would be that, for example, my daily backup status email would keep the most recent copy in my Inbox, and automatically archive older ones. Same for newsletters - if I didn't read last week's one, I'm realistically never going to, so once it's more than a couple of weeks stale, just get it out of my Inbox.

Thankfully, Google has an indirect way of making this sort of thing work - [Google Apps Script](https://developers.google.com/apps-script/). You can trigger small JavaScript scripts to run every so often, and operate on your data in various Google apps, including Gmail.

So, I quickly wrote [this script](https://gist.github.com/cmsj/0d12c452277f32704f347c7fe117215a) and it runs every few hours now:

```javascript
// Configuration data
// Each config should have the following keys:
//  * age_min: maps to 'older_than:' in gmail query terms
//  * age_max: maps to 'newer_than:' in gmail query terms
//  * query: freeform gmail query terms to match against
//
// The age_min/age_max values don't need to exist, given the freeform query value,
// but age_min forces you to think about how frequent the emails are, and age_max
// forces you to not search for every single email tha matches the query
//
// TODO:
//  * Add a per-config flag that skips the archiving if there's only one matching thread (so the most recent matching email always stays in Inbox)
var configs = [
  { age_min:"14d", age_max:"90d", query:"subject:(Benedict's Newsletter)" },
  { age_min:"7d",  age_max:"30d", query:"from:hello@visualping.io subject:gnubert" },
  { age_min:"1d",  age_max:"7d",  query:"subject:(Nightly clone to Thunderbay4 Successfully)" },
  { age_min:"1d",  age_max:"7d",  query:"from:Amazon subject:(Arriving today)" },
  ];

function processInbox() {
  for (var config_key in configs) {
    var config = configs[config_key];
    Logger.log("Processing query: " + config["query"]);

    var threads = GmailApp.search("in:inbox " + config["query"] + " newer_than:" + config["age_max"] + " older_than:" + config["age_min"]);
    for (var thread_key in threads) {
      var thread = threads[thread_key];
      Logger.log("  Archiving: " + thread.getFirstMessageSubject());

      thread.markRead();
      thread.moveToArchive();
    }
  }
}
```

(apologies for the very basic JavaScript - it's not a language I have any real desire to be good at. Don't @ me).