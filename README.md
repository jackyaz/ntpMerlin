# ntpMerlin - NTP Daemon for AsusWRT Merlin - with graphs
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1bc89c12c4bf44b49b28161f328e49b0)](https://www.codacy.com/app/jackyaz/ntpMerlin?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/ntpMerlin&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/ntpMerlin.svg?branch=master)](https://travis-ci.com/jackyaz/ntpMerlin)

## v2.0.0
### Updated on 2019-07-04
## About
Run an NTP server for your network on your router. Graphs available for NTP accuracy on the Tools page of the WebUI.

ntpMerlin is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

Inspired by [kvic](https://github.com/kvic-z)'s [project](https://github.com/kvic-z/goodies-asuswrt/wiki/Install-NTP-Daemon-for-Asuswrt-Merlin)

![Menu UI](https://puu.sh/DOJFc/f2a03e489b.png)

![Graph Example](https://puu.sh/DOJGn/1f7efed1d8.png)

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!
[**PayPal donation**](https://paypal.me/jackyaz21)

## Supported Models
### Models
All modes supported by [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/about). Models confirmed to work are below:
*   RT-AC66U_B1
*   RT-AC68U
*   RT-AC86U
*   RT-AC88U
*   RT-AX88U
*   RT-AC3100

### Firmware versions
You must be running firmware on the 384.XX branch [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/)

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/ntpMerlin/master/ntpmerlin.sh" -o "/jffs/scripts/ntpmerlin" && chmod 0755 /jffs/scripts/ntpmerlin && /jffs/scripts/ntpmerlin install
```

## Usage
To launch the ntpMerlin menu after installation, use:
```sh
ntpmerlin
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/ntpmerlin
```

## Updating
Launch ntpmerlin and select option u

## Help
Please post about any issues and problems here: [ntpMerlin on SNBForums](https://www.snbforums.com/threads/ntpmerlin-ntp-daemon-for-asuswrt-merlin.55756/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)
