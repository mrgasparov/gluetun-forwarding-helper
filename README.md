![plot](https://raw.githubusercontent.com/qdm12/gluetun/master/title.svg)

# [Gluetun Forwarding Helper](https://github.com/mrgasparov/gluetun-forwarding-helper)

[Gluetun](https://github.com/qdm12/gluetun/) is a lightweight swiss-knife-like VPN client to multiple VPN service providers. When used correctly, Gluetun allows you to launch applications on your NAS, or something like a Raspberry Pi, and ensure that all traffic is tunneled through your VPN provider. It takes care of complex firewall configurations, has a built-in kill-switch and other very useful features such as automatic port forwarding configuration.

Gluetun Forwarding Helper bridges the gap between Gluetun and target applications, updating listening port configuration automatically. It is intended to be used as a service within a [docker compose stack](#docker-compose), which guarantees the correct initialization sequence between Gluetun, Gluetun Forwarding Helper and the target application.

## Supported Target Applications

- [Nicotine+](https://nicotine-plus.org/)
- [Transmission](https://transmissionbt.com/)

If you would like to see other applications added to this list, please leave a feature request in the [issues section](https://github.com/mrgasparov/gluetun-forwarding-helper/issues)

## Supported Architectures

Simply pulling `mrgasparov/gluetun-forwarding-helper:latest` should retrieve the correct image for your arch, but you can also pull specific arch images via tags.

| Architecture | Available | Tag |
| :----: | :----: | ---- |
| x86-64 | ✅ | amd64-\<version tag\> |
| arm64 | ✅ | arm64v8-\<version tag\> |
| armhf | ✅ | armv7-\<version tag\> |

## Usage

### docker-compose

The example below shows integration with Nicotine+ and includes three services:

1. Gluetun (and basic consfiguration using ProtonVPN)
2. Gluetun Forwarding Helper
3. Nicotine+

This docker compose file makes use of the `network_mode` directive to allow Gluetun Forwarding Helper to query Gluetun's API and fetch the forwarded port, and to guarantee that Nicotine+ is exclusively connected to the internet via the VPN.

It also leverages the `depends_on` directive to guarantee that Gluetun Forwarding Helper only starts after Gluetun, and that Nicotine+ only starts after Gluetun Forwarding Helper has updated the forwarded port on the Nicotine+ configuration file.

Another crucial aspect to this setup is that the Nicotine+ config folder on the host - `/home/user/nicotine/config` in this particular example - is being shared with Gluetun Forwarding Helper, so that it is able to update the forwarded port on the Nicotine+ configuration file.

```yaml
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    ports:
      - 6080:6080/tcp
    environment:
      - VPN_SERVICE_PROVIDER=custom
      - VPN_TYPE=wireguard
      - WIREGUARD_PUBLIC_KEY=XXX
      - WIREGUARD_PRIVATE_KEY=XXX
      - WIREGUARD_ADDRESSES=10.2.0.2/32
      - VPN_ENDPOINT_IP=1.2.3.4
      - VPN_ENDPOINT_PORT=1.2.3.4
      - VPN_DNS_ADDRESS=10.2.0.1
      - VPN_PORT_FORWARDING=on
      - VPN_PORT_FORWARDING_PROVIDER=protonvpn
      - TZ=Europe/Berlin
  gluetun-forwarding-helper:
    image: mrgasparov/gluetun-forwarding-helper:latest
    network_mode: service:gluetun
    depends_on: 
      - gluetun
    environment:
      - SERVICE=nicotine+
    volumes:
      - /home/user/nicotine/data/.config/nicotine:/config
  nicotine:
    image: mrgasparov/nicotine-novnc:latest
    network_mode: service:gluetun
    restart: unless-stopped
    depends_on:
      gluetun-forwarding-helper:
        condition: service_completed_successfully
        restart: true
    environment:
      - RESOLUTION=1920x1080
    volumes:
      - /home/user/nicotine/data:/data
      - /home/user/nicotine/downloads:/downloads
```

## Parameters

### Environment Variables

| Variable | Description | Required
| :----: | --- | :---: |
| `SERVICE` | Defines the [target application](#supported-target-applications). Options are `nicotine+`, `transmission` | Yes

### Volumes

| Volume | Description | Required
| :----: | --- | :---: |
| `/config` | Path to mount the configuration folder of the target application | Yes
