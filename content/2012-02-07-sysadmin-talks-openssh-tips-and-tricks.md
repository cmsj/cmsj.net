title: A sysadmin talks OpenSSH tips and tricks
slug: sysadmin-talks-openssh-tips-and-tricks
date: 2012-02-07


# My take on more advanced SSH usage

I've seen a few articles recently on sites like HackerNews which claimed to cover some advanced SSH techniques/tricks. They were good articles, but for me (as a systems administrator) didn't get into the really powerful guts of OpenSSH.

So, I figured that I ought to pony up and write about some of the more advanced tricks that I have either used or seen others use. These will most likely be relevant to people who manage tens/hundreds of servers via SSH. Some of them are about actual configuration options for OpenSSH, others are recommendations for ways of working with OpenSSH.

## Generate your ~/.ssh/config

This isn't strictly an OpenSSH trick, but it's worth noting. If you have other sources of knowledge about your systems, automation can do a lot of the legwork for you in creating an SSH config. A perfect example here would be if you have some kind of database which knows about all your servers - you can use that to produce a fragment of an SSH config, then download it to your workstation and concatenate it with various other fragments into a final config. If you mix this with distributed version control, your entire team can share a broadly identical SSH config, with allowance for each person to have a personal fragment for their own preferences and personal hosts. I can't recommend this sort of collaborative working enough.

## Generate your ~/.ssh/known_hosts

This follows on from the previous item. If you have some kind of database of servers, teach it the SSH host key of each (usually something like `/etc/ssh/ssh_host_rsa_key.pub`) then you can export a file with the keys and hostnames in the correct format to use as a `known_hosts` file, e.g.:

`server1.company.com 10.0.0.101 ssh-rsa BLAHBLAHCRYPTOMUMBO`

You can then associate this with all the relevant hosts by including something like this in your `~/.ssh/config`:

```
Host *.mycompany.com
    UserKnownHostsFile ~/.ssh/generated_known_hosts
    StrictHostKeyChecking yes
```

This brings some serious advantages:

 * Safer - because you have pre-loaded all of the host keys and specified strict host key checking, SSH will prompt you if you connect to a machine and something has changed.
 * Discoverable - if you have tab completion, your shell will let you explore your infrastructure just by prodding the Tab key.

## Keep your private keys, private, private

This seems like it ought to be more obvious than it perhaps is... the private halves of your SSH keys are very privileged things. You should treat them with a great deal of respect. Don't put them on multiple machines (SSH keys are cheap to generate and revoke) and don't back them up.

## Know your limits

If you're going to write a config snippet that applies to a lot of hosts you can't match with a wildcard, you may end up with a very long `Host` line in your ssh config. It's worth remembering that there is a limit to the length of lines: 1024 characters. If you're going to need to exceed that, you will have to just have multiple `Host` sections with the same options.

## Set sane global defaults

```
HashKnownHosts no
Host *
    GSSAPIAuthentication no
    ForwardAgent no
```

These are very sane global defaults:

 * Known hosts hashing is good for keeping your hostnames secret from people who obtain your `known_hosts` file, but is also really very inconvenient as you are also unable to get any useful information out of the file yourself (such as tab completion). If you're still feeling paranoid you might consider tightening the permissions on your `known_hosts` file as it may be readable by other users on your workstation.
 * GSSAPI is very unlikely to be something you need, it's just slowing things down if it's enabled.
 * Agent forwarding can be tremendously dangerous and should, I think, be actively and passionately discouraged. It ought to be a nice feature, but it requires that you trust remote hosts unequivocally as if they had your private keys, because functionally speaking, they do. They don't actually have the private key material, but any sufficiently privileged process on the remote server can connect back to the SSH agent running on your workstation and request it respond to challenges from an SSH server. If you keep your keys unlocked in an SSH agent, this gives any privileged attacker on a server you are logged into, trivial access to any other machine your keys can SSH into. If you somehow depend on using agent forwarding with Internet facing servers, please re-consider your security model (unless you are able to robustly and accurately argue why your usage is safe, but if that is the case then you don't need to be reading a post like this!)

## Notify useful metadata

If you're using a Linux or OSX desktop, you either have something like `notify-send(1)` or Growl for desktop notifications. You can hook this into your SSH config to display useful metadata to yourself. The easiest way to do this is via the `LocalCommand` option:

```
Host *
    PermitLocalCommand yes
    LocalCommand /home/user/bin/ssh-notify.sh %h
```

This will call the `ssh-notify.sh` script every time you SSH to a host, passing the hostname you gave, as an argument.  In the script you probably want to ensure you're actually in an interactive terminal and not some kind of backgrounded batch session - this can be done trivially by ensuring that `tty -s` returns zero. Now the script just needs to go and fetch some metadata about the server you're connecting to (e.g. its physical location, the services that run on it, its hardware specs, etc.) and format them into a command that will display a notification.

## Sidestep overzealous key agents

If you have a lot of SSH keys in your ssh-agent (e.g. more than about 5) you may have noticed that SSHing to machines which want a password, or those which you wish to use a specific key that isn't in your agent, can be quite tricky. The reason for this is that OpenSSH currently seems to talk to the agent in preference to obeying command line options (i.e. `-i`) or config file directives (i.e. `IdentityFile` or PreferredAuthentications). You can force the behaviour you are asking for with the `IdentitiesOnly` option, e.g.:

```
Host server1.company.com
    IdentityFile /some/rarely/used/ssh.key
    IdentitiesOnly yes
```

(on a command line you would add this with `-o IdentitiesOnly=yes`)

## Match hosts with wildcards

Sometimes you need to talk to a lot of almost identically-named servers. Obviously SSH has a way to make this easier or I wouldn't be mentioning this. For example, if you needed to ssh to a cluster of remote management devices:

```
Host *.company.com management-rack-??.company.com
    User root
    PreferredAuthentications password
```

This will match anything ending in `.company.com` and also anything that starts with `management-rack-` and then has two characters, followed by `.company.com`.

## Per-host SSH keys

You may have some machines where you have a different key for each machine. By naming them after the fully qualified domain names of the hosts they relate to, you can skip over a more tedious SSH config with something like the following:

```
Host server-??.company.com
    IdentityFile /some/path/id_rsa-%h
```

(the `%h` will be substituted with the FQDN you're SSHing to. The `ssh_config` man page lists a few other available substitutions.)

## Use fake, per-network port forwarding hosts

If you have network management devices which require web access that you normally forward ports for with the `-L` option, consider constructing a fake host in your SSH config which establishes all of the port forwards you need for that network/datacentre/etc:

```
Host port-forwards-site1.company.com
    Hostname server1.company.com
    LocalForward 1234 10.0.0.101:1234
```

This also means that your forwards will be on the same port each time, which makes saving certificates in your browser a reasonable undertaking. All you need to do is `ssh port-forwards-site1.company.com` (using nifty Tab completion of course!) and you're done. If you don't want it tying up a terminal you can add the options `-f` and `-N` to your command line, which will establish the ssh connection in the background.

If you're using programs which support SOCKS (e.g. Firefox and many other desktop Linux apps) you can use the `DynamicForward` option to send traffic over the SSH connection without having to add `LocalForward` entries for each port you care about. Used with a browser extension such as FoxyProxy (which lets you configure multiple proxies based on wildcard/regexp URL matches) makes for a very flexible setup.

## Use an SSH jump host

Rather than have tens/dozens/hundreds/etc of servers holding their SSH port open to the Internet and being battered with brute force password cracking attempts, you might consider having a single host listening (or a single host per network perhaps), which you can proxy your SSH connections through.

If you do consider something like this, you must resist the temptation to place private keys on the jump host - to do so would utterly defeat the point.

Instead, you can use an old, but very nifty trick that completely hides the jump host from your day-to-day usage:

```
Host jumphost.company.com
    ProxyCommand none
Host *.company.com
    ProxyCommand ssh jumphost.company.com nc -q0 %h %p
```

You might wonder what on earth that is doing, but it's really quite simple. The first `Host` stanza just means we won't use any special commands to connect to the jump host itself. The second `Host` stanza says that in order to connect to anything ending in `.company.com` (but excluding `jumphost.company.com` because it just matched the previous stanza) we will first SSH to the jump host and then use `nc(1)` (i.e. netcat) to connect to the relevant port (`%p`) on the host we originally asked for (`%h`). Your local SSH client now has a session open to the jump host which is acting like it's a socket to the SSH port on the host you wanted to talk to, so it just uses that connection to establish an SSH session with the machine you wanted. Simple!

For those of you lucky enough to be connecting to servers that have OpenSSH 5.4 or newer, you can replace the jump host `ProxyCommand` with:

`ProxyCommand ssh -W %h:%p jumphost.company.com`

## Re-use existing SSH connections

Some people swear by this trick, but because I'm very close to my servers and have a decent CPU, the setup time for connections doesn't bother me. Folks who are many milliseconds from their servers, or who don't have unquenchable techno-lust for new workstations, may appreciate saving some time when establishing SSH connections.

The idea is that OpenSSH can place connections into the background automatically, and re-use those existing secure channels when you ask for a new `ssh(1)`, `scp(1)` or `sftp(1)` connections to hosts you have already spoken to. The configuration I would recommend for this, would be:

```
Host *
    ControlMaster auto
    ControlPath ~/.ssh/control/%h-%l-%p
    ControlPersist 600
```

This will do several things:

 * `ControlMaster auto` will cause OpenSSH to establish the "master" connection sockets as needed, falling back to normal connections if something is wrong.
 * The `ControlPath` option specifies where the connection sockets will live. Here we are placing them in a directory and giving them filenames that consist of the hostname, login username and port, which ought to be sufficient to uniquely identify each connection. If you need to get more specific, you can place this section near the end of your config and have explicit `ControlPath` entries in earlier `Host` stanzas.
 * `ControlPersist 600` causes the master connections to die if they are idle for 10 minutes. The default is that they live on as long as your network is connected - if you have hundreds of servers this will add up to an awful lot of `ssh(1)` processes running on your workstation! Depending on your needs, 10 minutes may not be long enough.

*Note:* You should make the `~/.ssh/control` directory ahead of time and ensure that only your user can access it.

## Cope with old/buggy SSH devices

Perhaps you have a bunch of management devices in your infrastructure and some of them are a few years old already. Should you find yourself trying to SSH to them, you might find that your connections don't work very well. Perhaps your SSH client is too new and is offering algorithms their creaky old SSH servers can't abide. You can strip down the long default list of algorithms to this to ones that a particular device supports, e.g.:

```
Host power-device-1.company.com
    HostkeyAlgorithms ssh-rsa,ssh-dss
```

## That's all folks

Those are the most useful tips and tricks I have for now. Hopefully someone will read this and think "hah! I can do ***much*** more advanced stuff than that!" and one-up me :)

Do feel free to comment if you do have something sneaky to add, I'll gladly steal your ideas!
