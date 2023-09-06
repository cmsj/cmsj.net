title: Running Tailscale in Docker
slug: tailscaledocker
date: 2023-08-19


I run most of my home services in Docker, and I decided it was time to migrate Tailscale from the host into Docker too.

This turned out to be an interesting journey, but I figured I'd talk about it here for anyone else hitting the same issues.

Here is my resulting Docker compose yaml:

```yaml
  tailscale:
    hostname: tailscale
    image: tailscale/tailscale:latest
    restart: unless-stopped
    network_mode: "host" # Easy mode
    privileged: true # I'm only about 80% sure this is required
    volumes:
      - /srv/ssdtank/docker/tailscale/data:/var/lib # tailscale/tailscale.state in here is where our authkey lives
      - /dev/net/tun:/dev/net/tun
      - /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket # This seems kinda terrible, but the daemon complains a lot if it can't connect to this
    cap_add: # Required
      - NET_ADMIN
      - NET_RAW
    environment:
      TS_HOSTNAME: "lolserver"
      TS_STATE_DIR: "/var/lib/tailscale" # This gives us a persistent entry in TS Machines, rather than Epehmeral
      TS_USERSPACE: false # Bizarrely, even if you bind /dev/net/tun in, you still need to tell the image to not use userspace networking
      TS_AUTH_ONCE: false # If you have a config error somewhere, and this is set to true, it'll be really hard to figure it out
      TS_ACCEPT_DNS: false # I don't want TS pushing any DNS to me.
      TS_ROUTES: "10.0.88.0/24,10.0.91.0/24" # Docs say this is for accepting routes. Code says it's for advertising routes. Awesome.
      TS_EXTRA_ARGS: "--advertise-exit-node"
    labels:
      com.centurylinklabs.watchtower.enable: "true"
```

Important things to note are:

 * `TS_STATE_DIR` is useful if you want a persistent node rather than an Ephemeral one (I'm not running this as part of some app deployment, this is LAN infrastructure)
 * `TS_USERSPACE` shouldn't just always default to `true`, it should check if `/dev/net/tun` is available, but it doesn't, so you have to force it to `false` if you want kernel networking.
 * `TS_AUTH_ONCE` is great, but if you have an error in the lower level networking setup, having this set to `true` will hide it on restarts of the container. I suggest keeping this `false`.
 * `TS_ROUTES` is currently wrong in the documentation. It is described as being for *accepting* routes *from* other hosts, but it's actually for *advertising* routes *to* other hosts.
