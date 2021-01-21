# ntpMerlin
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1bc89c12c4bf44b49b28161f328e49b0)](https://www.codacy.com/app/jackyaz/ntpMerlin?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/ntpMerlin&amp;utm_campaign=Badge_Grade)
[![Build Status](https://travis-ci.com/jackyaz/ntpMerlin.svg?branch=master)](https://travis-ci.com/jackyaz/ntpMerlin)

## v3.2.0
### Updated on 2020-01-21
## About
ntpMerlin implements an NTP time server for AsusWRT Merlin with charts for daily, weekly and monthly summaries of performance. A choice between ntpd and chrony is available.

ntpMerlin is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!

[**PayPal donation**](https://paypal.me/jackyaz21)

[**Buy me a coffee**](https://www.buymeacoffee.com/jackyaz)

## Supported firmware versions
You must be running firmware Merlin 384.15/384.13_4 or Fork 43E5 (or later) [Asuswrt-Merlin](https://asuswrt.lostrealm.ca/)

## Installation
Using your preferred SSH client/terminal, copy and paste the following command, then press Enter:

```sh
/usr/sbin/curl --retry 3 "https://raw.githubusercontent.com/jackyaz/ntpMerlin/master/ntpmerlin.sh" -o "/jffs/scripts/ntpmerlin" && chmod 0755 /jffs/scripts/ntpmerlin && /jffs/scripts/ntpmerlin install
```

## Usage
### WebUI
ntpMerlin can be configured via the WebUI, in the Addons section.

### Command Line
To launch the ntpMerlin menu after installation, use:
```sh
ntpmerlin
```

If this does not work, you will need to use the full path:
```sh
/jffs/scripts/ntpmerlin
```

## Screenshots

![WebUI](https://puu.sh/H93BK/957e542b10.png)

![CLI UI](https://puu.sh/GFJD7/b48a8bf2bf.png)

## Help
Please post about any issues and problems here: [ntpMerlin on SNBForums](https://www.snbforums.com/threads/ntpmerlin-ntp-daemon-for-asuswrt-merlin.55756/)

## FAQs
### I haven't used scripts before on AsusWRT-Merlin
If this is the first time you are using scripts, don't panic! In your router's WebUI, go to the Administration area of the left menu, and then the System tab. Set Enable JFFS custom scripts and configs to Yes.

Further reading about scripts is available here: [AsusWRT-Merlin User-scripts](https://github.com/RMerl/asuswrt-merlin/wiki/User-scripts)

![WebUI enable scripts](https://puu.sh/A3wnG/00a43283ed.png)
