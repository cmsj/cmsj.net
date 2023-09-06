title: Mounting a separate partition for Scrypted NVR storage in Home Assistant OS
slug: haosscryptednvr
date: 2023-09-06


All of my smart home stuff is running in Home Assistant, and I'm using their OS on a Mini PC.

One of the things I'm running on that OS is the Scrypted Add-On to bridge my generic RTSP cameras into HomeKit, and to use Scrypted's NVR.

By default, Scrypted will be storing NVR recordings in HassOS' `data` partition. I wanted to make sure that even if the NVR goes wild and fills the disk, the rest of my Home Assistant system wouldn't have to deal with running out of disk space, so I started looking for a way to configure HassOS and/or Scrypted to store the NVR recordings elsewhere. Turns out that isn't directly possible, but there is a very useful feature of HassOS that makes it possible.

Specifically, that feature is that you can import `udev` rules. With that I can ensure that a dedicated partition can be mounted in the location that the NVR recordings will be written, and now even if Scrypted goes haywire and runs that partition out of space, the rest of the system will function normally.

The official documentation for how to import `udev` rules (amongst many other useful things) is [here](https://github.com/home-assistant/operating-system/blob/dev/Documentation/configuration.md), but the approximate set of steps is:

 * Arrange for there to be a partition available on your Home Assistant OS machine, formatted as `ext4`, with the label `NVR`. I put a second disk in, so it's completely separate from the boot disk which Home Assistant OS may choose to modify later.
 * Format a USB stick as FAT32, named `CONFIG`
 * Create a directory on that stick with the name `udev`
 * In that `udev` folder create a plain text file called `80-mount-scrypted-nvr-volume.rules`

The contents of that rules file should be:

```
# This will mount a partition with the label "NVR" to: /mnt/data/supervisor/addons/data/09e60fb6_scrypted/scrypted_nvr/

# Import partition info into environment variables
IMPORT{program}="/usr/sbin/blkid -o udev -p %N"

# Exit if the partition is not a filesystem
ENV{ID_FS_USAGE}!="filesystem", GOTO="abort_rule"

# Exit if the partition isn't for NVR data
ENV{ID_FS_LABEL}!="NVR", GOTO="abort_rule"

# Store the mountpoint
ENV{mount_point}="/mnt/data/supervisor/addons/data/09e60fb6_scrypted/scrypted_nvr/"

# Mount the device on 'add' action (e.g. it was just connected to USB)
ACTION=="add", RUN{program}+="/usr/bin/mkdir -p %E{mount_point}", RUN{program}+="/usr/bin/systemd-mount --no-block --automount=no --collect $devnode %E{mount_point}"

# Umount the device on 'remove' action (a.k.a unplug or eject the USB drive)
ACTION=="remove", ENV{dir_name}!="", RUN{program}+="/usr/bin/systemd-umount %E{mount_point}"

# Exit
LABEL="abort_rule"
```

Notes:
 * As far as I know, the mountpoint for the Scrypted add-on should be stable, but I can't promise this.
 * This should be very safe as it will ignore any partition that isn't labelled `NVR`.
 * This should work with removable disks (e.g. USB), however, the Scrypted addon will not be stopped if you unplug the disk, so I would strongly recommend not doing that without stopping Scrypted first.
