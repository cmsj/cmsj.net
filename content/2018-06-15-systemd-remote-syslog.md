title: Receiving remote syslog events with systemd
slug: systemd-remote-syslog.md
date: 2018-06-15


[Systemd](https://www.freedesktop.org/wiki/Software/systemd/) includes `journald`, a fancy replacement for the venerable `syslog` daemon (and its descendents, `syslog-ng` and `rsyslog`).

One interesting, but frustrating, decision by `journald`'s maintainers is that it does not speak the syslog network protocol, so it's unable to receive remote syslog events. Remote syslog is a tremendously useful feature for aggregating log data from many hosts on a network - I've always used it so my network devices can log somewhere I'm likely to look at, but I haven't been able to do that since `journald` arrived.

While there are many ways to skin this goose, the method I've chosen is a tiny Python daemon that listens on syslog's UDP port (514), does minimal processing of the data and then feeds it into `journald` via its API, to get the data as rich as possible (since one of `journald`'s strengths is that it can store a lot more metadata about a log entry).

So, [here is the source](https://gist.github.com/cmsj/e03b6d28325ce5c3d5b255256278a330) for the daemon, and [here is the systemd service file](https://gist.github.com/cmsj/71f987d1129c5dc693243dd1aa5f8f4f) that manages it - note that it runs as an unprivileged user, with the sole privilege escalation of being able to bind to low port numbers (something only root can do normally).

The daemon is certainly not perfect (patches welcome!), but it works. Here is a `journald` log entry from one of my UniFi access points:

```
Jun 15 21:28:26 gnubert ("U7PG2,802aa8d48ab3,v3.9.27.8537")[23506]: kernel: [4251792.410000] [wifi1] FWLOG: [58855274] BEACON_EVENT_SWBA_SEND_FAILED (  )
```

(the more syslog-obsessed among you will notice that I'm setting the `identifier` to the hostname of the device that sent the message. Internally, the `facility` is mapped correctly, as is the `priority`. The text of the message then appears, prepended by its `identifier`.