title: Home networking like a pro - Part 1.1 - Network Storage Redux
slug: home-pro-part1-update
date: 2018-07-04


Back in [this post](/2017/06/22/home-pro-part-1-nas.html) I described having switched from a Mac Mini + DAS setup, to a Synology and an Intel NUC setup, for my file storage and server needs.

For a time it was good, but I found myself wanting to run more server daemons, and the NUC wasn't really able to keep up. The Synology was plodding along fine, but I made the decision to unify them all into a more beefy Linux machine.

So, I bought an AMD Ryzen 5 1600 CPU and an A320M motherboard, 16GB of RAM and a micro ATX case with 8 drive bays, and set to work. That quickly proved to be a disaster because Linux wasn't stable on the AMD CPU - I hadn't even thought to check, because why wouldn't Linux be stable on an x86_64 CPU in 2018?! With that lesson learned, I swapped out the board/CPU for an Intel i7-8700 and a Z370 motherboard.

I didn't go with FreeNAS as my previous post suggested I might, because ultimately I wanted complete control, so it's a plain Ubuntu Server machine that is fully managed by Ansible playbooks. In retrospect it was a mistake to try and delegate server tasks to an appliance like the Synology, and it was a further mistake to try and deal with that by getting the NUC - I should have just cut my losses and gone straight to a Linux server. Lesson learned!

Instead of getting lost in the weeds of purchase choices and justifications, instead let's look at some of the things I'm doing to the server with Ansible.

First up is root disk encryption - it's nice to know that your data is private when at rest, but a headless machine in a cupboard is not a fun place to be typing a password on boot. Fortunately I have two ways round this - firstly, a KVM (a Lantronix Spider) and secondly, one can add dropbear to an initramfs so you can ssh into the initramfs to enter the password.

Here's the playbook tasks that put dropbear into the initramfs:

```yaml
- name: Install dropbear-initramfs
  apt:
    name: dropbear-initramfs
    state: present

- name: Install busybox-static
  apt:
    name: busybox-static
    state: present

# This is necessary because of https://bugs.launchpad.net/ubuntu/+source/busybox/+bug/1651818
- name: Add initramfs hook to fix cryptroot-unlock
  copy:
    dest: /etc/initramfs-tools/hooks/zz-busybox-initramfs-fix
    src: dropbear-initramfs/zz-busybox-initramfs-fix
    mode: 0744
    owner: root
    group: root
  notify: update initramfs

- name: Configure dropbear-initramfs
  lineinfile:
    path: /etc/dropbear-initramfs/config
    regexp: 'DROPBEAR_OPTIONS'
    line: 'DROPBEAR_OPTIONS="-p 31337 -s -j -k -I 60"'
  notify: update initramfs

- name: Add dropbear authorized_keys
  copy:
    dest: /etc/dropbear-initramfs/authorized_keys
    src: dropbear-initramfs/dropbear-authorized_keys
    mode: 0600
    owner: root
    group: root
  notify: update initramfs

# The format of the ip= kernel parameter is: <client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>
# It comes from https://git.kernel.org/pub/scm/libs/klibc/klibc.git/tree/usr/kinit/ipconfig/README.ipconfig?id=HEAD
- name: Configure boot IP and consoleblanking
  lineinfile:
    path: /etc/default/grub
    regexp: 'GRUB_CMDLINE_LINUX_DEFAULT'
    line: 'GRUB_CMDLINE_LINUX_DEFAULT="ip=10.0.88.11::10.0.88.1:255.255.255.0:gnubert:enp0s31f6:none loglevel=7 consoleblank=0"'
  notify: update grub
```

While this does rely on some external files, the important one is `zz-busybox-initramfs-fix` which works around [a bug](https://bugs.launchpad.net/ubuntu/+source/busybox/+bug/1651818) in the busybox build that Ubuntu is currently using. Rather than paste the whole script here, you can see it [here](https://gist.github.com/cmsj/515fbf602f983e796ea11f95ce32d537).

The last task in the playbook configures Linux to boot with a particular networking config on a particular NIC, so you can ssh in. Once you're in, just run `cryptsetup-unlock` and your encrypted root is unlocked!

Another interesting thing I'm doing, is using [Borg](https://github.com/borgbackup) for some backups. It's a pretty clever backup system, and it works over SSH, so I use the following Ansible task to allow a particular SSH key to log in to the server as root, in a way that forces it to use Borg:

```yaml
- name: Deploy ssh borg access
  authorized_key:
    user: root
    state: present
    key_options: 'command="/usr/bin/borg serve --restrict-to-path /srv/tank/backups/borg",restrict'
    key: "ssh-rsa BLAHBLAH cmsj@foo"
```

Now on client machines I can run ```borg create --exclude-caches --compression=zlib -v -p -s ssh://gnuborg:22/srv/tank/backups/borg/foo/backups.borg::cmsj-{utcnow} $HOME``` and because `gnuborg` is defined in `~/.ssh/config` it will use all the right ssh options (username, hostname and the SSH key created for this purpose):

```
Host gnuborg
  User root
  Hostname gnubert.local
  IdentityFile ~/.ssh/id_rsa_herborg
```
