# ntpMerlin
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/1bc89c12c4bf44b49b28161f328e49b0)](https://www.codacy.com/app/jackyaz/ntpMerlin?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=jackyaz/ntpMerlin&amp;utm_campaign=Badge_Grade)
![Shellcheck](https://github.com/jackyaz/ntpmerlin/actions/workflows/shellcheck.yml/badge.svg)

## v3.4.5
### Updated on 2021-08-05
## About
ntpMerlin implements an NTP time server for AsusWRT Merlin with charts for daily, weekly and monthly summaries of performance. A choice between ntpd and chrony is available.

ntpMerlin is free to use under the [GNU General Public License version 3](https://opensource.org/licenses/GPL-3.0) (GPL 3.0).

### Supporting development
Love the script and want to support future development? Any and all donations gratefully received!

| [![paypal](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_LG.gif)](https://www.paypal.com/donate/?hosted_button_id=47UTYVRBDKSTL) <br /><br /> [**PayPal donation**](https://www.paypal.com/donate/?hosted_button_id=47UTYVRBDKSTL) | [![paypal](https://puu.sh/IAhtp/3788f3a473.png)](https://www.paypal.com/donate/?hosted_button_id=47UTYVRBDKSTL) |
| :----: | --- |

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

![WebUI](https://puu.sh/HF2uc/396909c6c7.png)

![CLI UI](https://puu.sh/HF2u3/02f06c84a4.png)

## Help
Please post about any issues and problems here: [Asuswrt-Merlin AddOns on SNBForums](https://www.snbforums.com/forums/asuswrt-merlin-addons.60/?prefix_id=22)
