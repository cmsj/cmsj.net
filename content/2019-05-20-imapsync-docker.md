title: Overengineered email migration
slug: imapsync-docker
date: 2019-05-20


I recently had the need to migrate someone in my family off an old ISP email account, onto a more modern email account, without simply shutting down the old account. The old address has been given out to people/companies for at least a decade, so it's simply not practical to stop receiving its email.

Initially, I used the ISP's own server-side filtering to forward emails on to the new account and then delete them, however, all of the fantabulous anti-spam technologies that are used these days, conspired to make it unreliable.

So instead, I decided that since I can access IMAP on both accounts, and I have a server at home running all the time, I'd just use some kind of local tool to fetch any emails that show up on the old account and move them to the new one.

After some investigation, I settled on [imapsync](https://imapsync.lamiral.info/) as the most capable tool for the job. It's ultimately "just" a Perl script, but it's fantastically well maintained by Gilles Lamiral. It's sort of unclear whether it's Open Source or not, but I'm a big fan of supporting FOSS development, so I happily paid the 60€ Gilles asks for.

My strong preference these days is always to run my local services in Docker, and fortunately Gilles publishes an [official imapsync Dockule](https://hub.docker.com/r/gilleslamiral/imapsync/) so I set to work in Ansible to orchestrate all of the pieces I needed to get this running.

The first piece was a simple bash script that calls imapsync with all of the necessary command line options:

```bash
#!/bin/bash
# This is /usr/local/bin/imapsync-user-isp-fancyplace.sh
/usr/bin/docker run -u root --rm -v/root/.imap-pass-isp.txt:/isp-pass.txt -v/root/.imap-pass-fancyplace.txt:/fancyplace-pass.txt gilleslamiral/imapsync \
    imapsync \
        --host1 imap.isp.net --port1 993 --user1 olduser@isp.net --passfile1 /isp-pass.txt --ssl1 --sslargs1 SSL_verify_mode=1 \
        --host2 imap.fancyplace.com --port2 993 --user2 newuser@fancyplace.com --passfile2 /fancyplace-pass.txt --ssl2 --sslargs2 SSL_verify_mode=1 \
        --automap \
        --nofoldersizes --nofoldersizesatend \
        --delete1 --noexpungeaftereach \
        --expunge1
```

Please test this with the ```--dry``` option if you ever want to do this - the ```--automap``` option worked incredibly well for me (even translating between languages for folders like "Sent Messages"), but check that for yourself.

What this script will do is start a Docker container and run imapsync within it, which will then check all folders on the old IMAP server and sync any found emails over to the new IMAP server *and then delete them from the old server*. This is unfortunately necessary because the old ISP in question has a pretty low storage limit and I don't want future email flow to stop because we forgot to go and delete old emails. imapsync appears to be pretty careful about making sure an email has synced correctly before it deletes it from the old server, so I'm not super worried about data loss.

The IMAP passwords are read from files that live in /root/ on my server (with ```0400``` permissions) and they are mounted through into the container. For the new IMAP account, this is a "per-device" password rather than the main account password, so it won't change, and is easy to revoke.

This isn't a complete setup yet though, because after doing one sync, imapsync will exit and Docker will obey its ```--rm``` option and delete the container. What we now need is a regular trigger to run this script and while this used to mean cron, nowadays it could also mean a [systemd timer](https://www.freedesktop.org/software/systemd/man/systemd.timer.html). So, I created a simple systemd service file which gets written to ```/etc/systemd/system/imapsync-user-isp-fancyplace.service``` and enabled in systemd:

```
[Unit]
Description=User IMAP Sync
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/imapsync-user-isp-fancyplace.sh
Restart=no
TimeoutSec=120
```

and a systemd timer file which gets written to ```/etc/systemd/system/imapsync-user-isp-fancyplace.timer```, and then both enabled and started in systemd:

```
[Unit]
Description=Trigger User IMAP Sync

[Timer]
Unit=imapsync-user-isp-fancyplace.service
OnUnitActiveSec=10min
OnUnitInactiveSec=10min
Persistent=true

[Install]
WantedBy=timers.target
```

This will trigger every 10 minutes and start the specified service, which executes the script that starts the Dockule to sync the email. Simple!

And just to show a useful command, you can check when the timer last triggered, and when it will trigger next, like this:


```
# systemctl list-timers
NEXT                         LEFT          LAST                         PASSED             UNIT                               ACTIVATES
Mon 2019-05-20 17:38:13 BST  27s left      Mon 2019-05-20 17:28:13 BST  9min ago           imapsync-user-isp-fancyplace.timer imapsync-user-isp-fancyplace.service
[snip unrelated timers]

9 timers listed.
Pass --all to see loaded but inactive timers, too.
```
