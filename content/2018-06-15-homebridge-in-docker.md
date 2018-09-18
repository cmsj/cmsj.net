title: Homebridge in Docker, an adventure in networking
slug: homebridge-in-docker.md
date: 2018-06-15


[Homebridge](https://github.com/nfarina/homebridge) is a great way of connecting [loads](https://www.npmjs.com/search?q=homebridge) of devices that don't support Apple's [HomeKit](https://www.apple.com/uk/ios/home/), to your iOS devices. It consists of a daemon that understands the [HomeKit Accessory Protocol](https://developer.apple.com/support/homekit-accessory-protocol/) and [many plugins](https://www.npmjs.com/search?q=homebridge) that talk to other devices/services.

My home server is running Ubuntu, so installing Homebridge is fairly trivial, except I run all my services in [Docker](https://www.docker.com) containers. To make things even more fun, I don't build or manage the containers by hand - the building is done by [Docker Hub](https://hub.docker.com/u/cmsj/) and the containers are deployed and managed by [Ansible](https://www.ansible.com/).

So far so good, except that for a long time Homebridge used [Avahi](https://www.avahi.org/) (an Open Source implementation of Apple's Bonjour host/service discovery protocol) to announce its devices. That presented a small challenge in that I didn't want to have Avahi running only in that container, so I had to bind mount `/var/run/avahi-daemon/` into the container.

I recently rebuilt my Homebridge container to pull it up to the latest versions of Homebridge and the plugins I use, but it was no longer announcing devices on my LAN, and there were no mentions of Avahi in its log. After some digging, it turns out that the HomeKit Accessory Protocol (HAP) library that Homebridge uses, now instantiates its own multicast DNS stack rather than using Avahi.

Apart from not actually working, this was great news, I could remove the `/var/run` bind mount from the container, making things more secure, I just needed to figure out why it wasn't showing up.

The HAP library that Homebridge uses, ends up depending on [this library](https://github.com/mafintosh/multicast-dns) to implement mDNS and it makes [a very simple](https://github.com/mafintosh/multicast-dns/blob/master/index.js#L147) decision about which network interface it should use. In my case, it was choosing the `docker0` bridge interface which explicitly isn't connected to the outside world. With no configuration options at the Homebridge level to influence the choice of interface, I had to solve the problem at the Docker network layer.

So, the answer was the following Ansible task to create a Docker network that is attached to my LAN interface (`bridge0`) and give it a small portion of a reserved segment in the IP subnet I use:

```YAML
- name: Configure LANbridge network
  docker_network:
    name: lanbridge
    driver: macvlan
    driver_options:
      parent: bridge0
    ipam_options:
      subnet: '10.0.88.0/24'
      gateway: '10.0.88.1'
      iprange: '10.0.88.32/29'
```

then change the task for the Homebridge container to use this network:

```
  network_mode: lanbridge
```

and now Homebridge is up to date, and working, plus I have a Docker network I can use in the future if any other containerised services need to be very close to the LAN.