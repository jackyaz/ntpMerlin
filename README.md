# ntpdMerlin - NTP Daemon for AsusWRT Merlin - with graphs
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1bc89c12c4bf44b49b28161f328e49b0)](https://www.codacy.com/app/jackyaz/ntpdMerlin?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/ntpdMerlin&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/ntpdMerlin.svg?branch=master)](https://travis-ci.com/jackyaz/ntpdMerlin)

## v1.0.5
### Updated on 2019-03-17
## About
Run an NTP server for your network for your network. Graphs available for NTP accuracy on the Tools page of the WebUI

ntpdMerlin is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

This script serves as a user-friendly installer for [kvic](https://github.com/kvic-z)'s [project](https://github.com/kvic-z/goodies-asuswrt/wiki/Install-NTP-Daemon-for-Asuswrt-Merlin)

![Menu UI](https://puu.sh/D1gDp/912cbe5884.png)

## Supported Models
### Models
All modes supported by [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/about). Models confirmed to work are below:
*   RT-AC86U

### Firmware versions
You must be running firmware no older than:
*   [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/) 380.68

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/ntpdMerlin/master/ntpmerlin.sh" -o "/jffs/scripts/ntpmerlin" && chmod 0755 /jffs/scripts/ntpmerlin && /jffs/scripts/ntpmerlin install
```

## Usage
To launch the ntpdMerlin menu after installation, use:
```sh
ntpmerlin
```

If you do not have Entware installed, you will need to use the full path:
```sh
/jffs/scripts/ntpmerlin
```

## Updating
Launch ntpmerlin and select option u

## Help
Please post about any issues and problems here: [ntpdMerlin on SNBForums](https://www.snbforums.com/threads/ntp-daemon-for-asuswrt-merlin.28041/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)

#### Supporting development
[**PayPal donation**](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KWHP2LFLJV84Q)
