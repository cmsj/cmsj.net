title: Homebridge server monitoring
slug: homebridge-server-monitoring
date: 2018-07-02


[Homebridge](https://github.com/nfarina/homebridge) is a great way to expose arbitrary devices to Apple's HomeKit platform. It has helped bridge the Google Nest and Netgear Arlo devices I have in my home, into my iOS devices, since neither of those manufacturers appear to be interested in becoming officially HomeKit compatible.

London has been having a little bit of a heatwave recently and it got me thinking about the Linux server I have running in a closet under the stairs - it has pretty poor airflow available to it, and I didn't know how hot its CPU was getting.

So, by the power of JavaScript, Homebridge and Linux's `/sys` filesystem, I was able to quickly whip up [a plugin](https://github.com/cmsj/homebridge-linux-temperature) for Homebridge that will read an entry from Linux's temperature monitoring interface, and present it to HomeKit. In theory I could use it for sending notifications, but in practice I'm doing that via [Grafana](https://grafana.com/) - the purpose of getting the information in HomeKit is so I can ask Siri what the server's temperature is.

The configuration is very simple, allowing you to configure one temperature sensor per instance of the plugin (but you could define multiple instances in your Homebridge `config.json`):

```json
{
    "accessory": "LinuxTemperature",
    "name": "gnubert",
    "sensor_path": "/sys/bus/platform/devices/coretemp.0/hwmon/hwmon0/temp1_input",
    "divisor": 1000
}
```

(`gnubert` is the hostname of my server).

Below is a screenshot showing the server's CPU temperature mingling with all of the Nest and Arlo items :)

![Screenshot](/images/2018-07-02-server-temp-homekit.jpg)
