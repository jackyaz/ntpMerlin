#!/bin/sh

##########################################################
##         _           __  __              _  _         ##
##        | |         |  \/  |            | |(_)        ##
##  _ __  | |_  _ __  | \  / |  ___  _ __ | | _  _ __   ##
## | '_ \ | __|| '_ \ | |\/| | / _ \| '__|| || || '_ \  ##
## | | | || |_ | |_) || |  | ||  __/| |   | || || | | | ##
## |_| |_| \__|| .__/ |_|  |_| \___||_|   |_||_||_| |_| ##
##             | |                                      ##
##             |_|                                      ##
##                                                      ##
##       https://github.com/jackyaz/ntpMerlin           ##
##                                                      ##
##########################################################

### Start of script variables ###
readonly SCRIPT_NAME="ntpMerlin"
#shellcheck disable=SC2019
#shellcheck disable=SC2018
readonly SCRIPT_NAME_LOWER=$(echo $SCRIPT_NAME | tr 'A-Z' 'a-z' | sed 's/d//')
readonly SCRIPT_VERSION="v2.3.0"
readonly SCRIPT_BRANCH="master"
readonly SCRIPT_REPO="https://raw.githubusercontent.com/jackyaz/$SCRIPT_NAME/$SCRIPT_BRANCH"
readonly OLD_SCRIPT_DIR="/jffs/scripts/$SCRIPT_NAME_LOWER.d"
readonly SCRIPT_DIR="/jffs/addons/$SCRIPT_NAME_LOWER.d"
readonly SCRIPT_WEBPAGE_DIR="$(readlink /www/user)"
readonly SCRIPT_WEB_DIR="$SCRIPT_WEBPAGE_DIR/$SCRIPT_NAME_LOWER"
readonly OLD_SHARED_DIR="/jffs/scripts/shared-jy"
readonly SHARED_DIR="/jffs/addons/shared-jy"
readonly SHARED_REPO="https://raw.githubusercontent.com/jackyaz/shared-jy/master"
readonly SHARED_WEB_DIR="$SCRIPT_WEBPAGE_DIR/shared-jy"
readonly CSV_OUTPUT_DIR="$SCRIPT_DIR/csv"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
[ -f /opt/bin/sqlite3 ] && SQLITE3_PATH=/opt/bin/sqlite3 || SQLITE3_PATH=/usr/sbin/sqlite3
### End of script variables ###

### Start of output format variables ###
readonly CRIT="\\e[41m"
readonly ERR="\\e[31m"
readonly WARN="\\e[33m"
readonly PASS="\\e[32m"
### End of output format variables ###

# $1 = print to syslog, $2 = message to print, $3 = log level
Print_Output(){
	if [ "$1" = "true" ]; then
		logger -t "$SCRIPT_NAME" "$2"
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	else
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$SCRIPT_NAME"
	fi
}

Firmware_Version_Check(){
	if [ "$1" = "install" ]; then
		if [ "$(uname -o)" = "ASUSWRT-Merlin" ] && [ "$(nvram get buildno | cut -f1 -d'.')" -ge "384" ]; then
			return 0
		else
			return 1
		fi
	elif [ "$1" = "webui" ]; then
		if nvram get rc_support | grep -qF "am_addons"; then
			return 0
		else
			return 1
		fi
	fi
}

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$SCRIPT_NAME$1.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r "/tmp/""$SCRIPT_NAME""$1"".lock")))
		if [ "$ageoflock" -gt 120 ]; then
			Print_Output "true" "Stale lock file found (>120 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' "/tmp/""$SCRIPT_NAME""$1"".lock")" >/dev/null 2>&1
			Clear_Lock "$1"
			echo "$$" > "/tmp/$SCRIPT_NAME$1.lock"
			return 0
		else
			Print_Output "true" "Lock file found (age: $ageoflock seconds) - stopping to prevent duplicate runs" "$ERR"
			if [ -z "$1" ] || [ "$1" = "redirect" ]; then
				exit 1
			else
				return 1
			fi
		fi
	else
		echo "$$" > "/tmp/$SCRIPT_NAME$1.lock"
		return 0
	fi
}

Clear_Lock(){
	rm -f "/tmp/$SCRIPT_NAME$1.lock" 2>/dev/null
	return 0
}

Update_Version(){
	if [ -z "$1" ]; then
		doupdate="false"
		localver=$(grep "SCRIPT_VERSION=" /jffs/scripts/"$SCRIPT_NAME_LOWER" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | grep -qF "jackyaz" || { Print_Output "true" "404 error detected - stopping update" "$ERR"; return 1; }
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		if [ "$localver" != "$serverver" ]; then
			doupdate="version"
		else
			localmd5="$(md5sum "/jffs/scripts/$SCRIPT_NAME_LOWER" | awk '{print $1}')"
			remotemd5="$(curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | md5sum | awk '{print $1}')"
			if [ "$localmd5" != "$remotemd5" ]; then
				doupdate="md5"
			fi
		fi
		
		if [ "$doupdate" = "version" ]; then
			Print_Output "true" "New version of $SCRIPT_NAME available - updating to $serverver" "$PASS"
		elif [ "$doupdate" = "md5" ]; then
			Print_Output "true" "MD5 hash of $SCRIPT_NAME does not match - downloading updated $serverver" "$PASS"
		fi
			
		Update_File "S77ntpd"
		Update_File "ntp.conf"
		Update_File "ntpdstats_www.asp"
		Update_File "redirect.htm"
		Update_File "addons.png"
		Update_File "chart.js"
		Update_File "chartjs-plugin-zoom.js"
		Update_File "chartjs-plugin-annotation.js"
		Update_File "chartjs-plugin-datasource.js"
		Update_File "hammerjs.js"
		Update_File "moment.js"
		
		if [ "$doupdate" != "false" ]; then
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" -o "/jffs/scripts/$SCRIPT_NAME_LOWER" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 "/jffs/scripts/$SCRIPT_NAME_LOWER"
			Clear_Lock "$2"
			exit 0
		else
			Print_Output "true" "No new version - latest is $localver" "$WARN"
			Clear_Lock "$2"
		fi
	fi
	
	case "$1" in
		force)
			serverver=$(/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" | grep "SCRIPT_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
			Print_Output "true" "Downloading latest version ($serverver) of $SCRIPT_NAME" "$PASS"
			Update_File "S77ntpd"
			Update_File "ntp.conf"
			Update_File "ntpdstats_www.asp"
			Update_File "redirect.htm"
			Update_File "addons.png"
			Update_File "chart.js"
			Update_File "chartjs-plugin-zoom.js"
			Update_File "chartjs-plugin-annotation.js"
			Update_File "chartjs-plugin-datasource.js"
			Update_File "hammerjs.js"
			Update_File "moment.js"
			/usr/sbin/curl -fsL --retry 3 "$SCRIPT_REPO/$SCRIPT_NAME_LOWER.sh" -o "/jffs/scripts/$SCRIPT_NAME_LOWER" && Print_Output "true" "$SCRIPT_NAME successfully updated"
			chmod 0755 "/jffs/scripts/$SCRIPT_NAME_LOWER"
			Clear_Lock
			exit 0
		;;
	esac
}
############################################################################

Update_File(){
	if [ "$1" = "S77ntpd" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "/opt/etc/init.d/$1" >/dev/null 2>&1; then
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			NTPD_Customise
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "ntp.conf" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if [ -f "$SCRIPT_DIR/$1.default" ]; then
			if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1.default" >/dev/null 2>&1; then
				Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1.default"
				Print_Output "true" "New default version of $1 downloaded to $SCRIPT_DIR/$1.default, please compare against your $SCRIPT_DIR/$1" "$PASS"
			fi
		else
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1.default"
			Print_Output "true" "$SCRIPT_DIR/$1.default does not exist, downloading now. Please compare against your $SCRIPT_DIR/$1" "$PASS"
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "ntpdstats_www.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SCRIPT_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "$SCRIPT_DIR/$1" >/dev/null 2>&1; then
			Get_WebUI_Page "$SCRIPT_DIR/$1"
			sed -i "\\~$MyPage~d" /tmp/menuTree.js
			rm -f "$SCRIPT_WEBPAGE_DIR/$MyPage" 2>/dev/null
			Download_File "$SCRIPT_REPO/$1" "$SCRIPT_DIR/$1"
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			Mount_WebUI
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "chart.js" ] || [ "$1" = "chartjs-plugin-zoom.js" ] || [ "$1" = "chartjs-plugin-annotation.js" ] || [ "$1" = "moment.js" ] || [ "$1" =  "hammerjs.js" ] || [ "$1" = "chartjs-plugin-datasource.js" ] || [ "$1" = "addons.png" ] || [ "$1" = "redirect.htm" ]; then
		tmpfile="/tmp/$1"
		Download_File "$SHARED_REPO/$1" "$tmpfile"
		if [ ! -f "$SHARED_DIR/$1" ]; then
			touch "$SHARED_DIR/$1"
		fi
		if ! diff -q "$tmpfile" "$SHARED_DIR/$1" >/dev/null 2>&1; then
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			Download_File "$SHARED_REPO/$1" "$SHARED_DIR/$1"
		fi
		rm -f "$tmpfile"
	else
		return 1
	fi
}

Validate_Number(){
	if [ "$2" -eq "$2" ] 2>/dev/null; then
		return 0
	else
		formatted="$(echo "$1" | sed -e 's/|/ /g')"
		if [ -z "$3" ]; then
			Print_Output "false" "$formatted - $2 is not a number" "$ERR"
		fi
		return 1
	fi
}

Create_Dirs(){
	if [ ! -d "$SCRIPT_DIR" ]; then
		mkdir -p "$SCRIPT_DIR"
	fi
	
	if [ ! -d "$CSV_OUTPUT_DIR" ]; then
		mkdir -p "$CSV_OUTPUT_DIR"
	fi
	
	if [ -d "$OLD_SCRIPT_DIR" ]; then
		mv "$OLD_SCRIPT_DIR" "$(dirname "$SCRIPT_DIR")"
		rm -rf "$OLD_SCRIPT_DIR"
	fi
	
	if [ -f "/jffs/configs/ntp.conf" ]; then
		mv "/jffs/configs/ntp.conf" "$SCRIPT_DIR/ntp.conf"
	fi
	
	if [ -f "/jffs/configs/ntp.conf.default" ]; then
		mv "/jffs/configs/ntp.conf.default" "$SCRIPT_DIR/ntp.conf.default"
	fi
	
	if [ ! -d "$SHARED_DIR" ]; then
		mkdir -p "$SHARED_DIR"
	fi
	
	if [ -d "$OLD_SHARED_DIR" ]; then
		mv "$OLD_SHARED_DIR" "$(dirname "$SHARED_DIR")"
		rm -rf "$OLD_SHARED_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEBPAGE_DIR" ]; then
		mkdir -p "$SCRIPT_WEBPAGE_DIR"
	fi
	
	if [ ! -d "$SCRIPT_WEB_DIR" ]; then
		mkdir -p "$SCRIPT_WEB_DIR"
	fi
	
	if [ ! -d "$SHARED_WEB_DIR" ]; then
		mkdir -p "$SHARED_WEB_DIR"
	fi
}

Create_Symlinks(){
	rm -f "$SCRIPT_WEB_DIR/"* 2>/dev/null
	rm -f "$SHARED_WEB_DIR/"* 2>/dev/null
	
	ln -s "$SCRIPT_DIR/ntpstatsdata.js" "$SCRIPT_WEB_DIR/ntpstatsdata.js" 2>/dev/null
	ln -s "$SCRIPT_DIR/ntpstatstext.js" "$SCRIPT_WEB_DIR/ntpstatstext.js" 2>/dev/null
	ln -s "$CSV_OUTPUT_DIR" "$SCRIPT_WEB_DIR/csv" 2>/dev/null
	
	ln -s "$SHARED_DIR/chart.js" "$SHARED_WEB_DIR/chart.js" 2>/dev/null
	ln -s "$SHARED_DIR/chartjs-plugin-zoom.js" "$SHARED_WEB_DIR/chartjs-plugin-zoom.js" 2>/dev/null
	ln -s "$SHARED_DIR/chartjs-plugin-annotation.js" "$SHARED_WEB_DIR/chartjs-plugin-annotation.js" 2>/dev/null
	ln -s "$SHARED_DIR/chartjs-plugin-datasource.js" "$SHARED_WEB_DIR/chartjs-plugin-datasource.js" 2>/dev/null
	ln -s "$SHARED_DIR/hammerjs.js" "$SHARED_WEB_DIR/hammerjs.js" 2>/dev/null
	ln -s "$SHARED_DIR/moment.js" "$SHARED_WEB_DIR/moment.js" 2>/dev/null
	ln -s "$SHARED_DIR/redirect.htm" "$SHARED_WEB_DIR/redirect.htm" 2>/dev/null
	ln -s "$SHARED_DIR/addons.png" "$SHARED_WEB_DIR/addons.png" 2>/dev/null
}

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME_LOWER generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "/jffs/scripts/$SCRIPT_NAME_LOWER generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$SCRIPT_NAME_LOWER generate"' "$1" "$2" &'' # '"$SCRIPT_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

Auto_DNSMASQ(){
	case $1 in
		create)
			if [ -f /jffs/configs/dnsmasq.conf.add ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/configs/dnsmasq.conf.add)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "dhcp-option=lan,42,$(nvram get lan_ipaddr)"' # '"$SCRIPT_NAME" /jffs/configs/dnsmasq.conf.add)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/configs/dnsmasq.conf.add
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "dhcp-option=lan,42,$(nvram get lan_ipaddr)"' # '"$SCRIPT_NAME" >> /jffs/configs/dnsmasq.conf.add
				fi
			else
				echo "" >> /jffs/configs/dnsmasq.conf.add
				# shellcheck disable=SC2016
				echo "dhcp-option=lan,42,$(nvram get lan_ipaddr)"' # '"$SCRIPT_NAME" >> /jffs/configs/dnsmasq.conf.add
				chmod 0644 /jffs/configs/dnsmasq.conf.add
			fi
		;;
		delete)
			if [ -f /jffs/configs/dnsmasq.conf.add ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/configs/dnsmasq.conf.add)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/configs/dnsmasq.conf.add
				fi
			fi
		;;
	esac
	
	service restart_dnsmasq >/dev/null 2>&1
}

Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME_LOWER startup"' # '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME_LOWER startup"' # '"$SCRIPT_NAME" >> /jffs/scripts/services-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/services-start
				echo "" >> /jffs/scripts/services-start
				echo "/jffs/scripts/$SCRIPT_NAME_LOWER startup"' # '"$SCRIPT_NAME" >> /jffs/scripts/services-start
				chmod 0755 /jffs/scripts/services-start
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
		;;
	esac
}

Auto_NAT(){
	case $1 in
		create)
			if [ -f /jffs/scripts/nat-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/nat-start)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$SCRIPT_NAME_LOWER ntpredirect"' # '"$SCRIPT_NAME" /jffs/scripts/nat-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/nat-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$SCRIPT_NAME_LOWER ntpredirect"' # '"$SCRIPT_NAME" >> /jffs/scripts/nat-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/nat-start
				echo "" >> /jffs/scripts/nat-start
				echo "/jffs/scripts/$SCRIPT_NAME_LOWER ntpredirect"' # '"$SCRIPT_NAME" >> /jffs/scripts/nat-start
				chmod 0755 /jffs/scripts/nat-start
			fi
		;;
		delete)
			if [ -f /jffs/scripts/nat-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/nat-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$SCRIPT_NAME"'/d' /jffs/scripts/nat-start
				fi
			fi
		;;
		check)
			if [ -f /jffs/scripts/nat-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$SCRIPT_NAME" /jffs/scripts/nat-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					return 0
				else
					return 1
				fi
			else
				return 1
			fi
		;;
	esac
}

Auto_Cron(){
	case $1 in
		create)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "$SCRIPT_NAME" "*/10 * * * * /jffs/scripts/$SCRIPT_NAME_LOWER generate"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -c "$SCRIPT_NAME")
			
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$SCRIPT_NAME"
			fi
		;;
	esac
}

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

NTP_Redirect(){
	case $1 in
		create)
			iptables -t nat -D PREROUTING -p udp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)" 2>/dev/null
			iptables -t nat -D PREROUTING -p tcp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)" 2>/dev/null
			iptables -t nat -A PREROUTING -p udp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)"
			iptables -t nat -A PREROUTING -p tcp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)"
			Auto_DNSMASQ create 2>/dev/null
		;;
		delete)
			iptables -t nat -D PREROUTING -p udp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)"
			iptables -t nat -D PREROUTING -p tcp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)"
			Auto_DNSMASQ delete 2>/dev/null
		;;
	esac
}

NTP_Firmware_Check(){
	ENABLED_NTPD="$(nvram get ntpd_enable)"
	if ! Validate_Number "" "$ENABLED_NTPD" "silent"; then ENABLED_NTPD=0; fi
	
	if [ "$ENABLED_NTPD" -eq 1 ]; then
		Print_Output "true" "Built-in ntpd is enabled and will conflict, it will be disabled" "$WARN"
		nvram set ntpd_enable=0
		nvram set ntpd_server_redir=0
		nvram commit
		service restart_time
		service restart_firewall
		return 1
	else
		return 0
	fi
}

Get_WebUI_Page () {
	for i in 1 2 3 4 5 6 7 8 9 10; do
		page="$SCRIPT_WEBPAGE_DIR/user$i.asp"
		if [ ! -f "$page" ] || [ "$(md5sum < "$1")" = "$(md5sum < "$page")" ]; then
			MyPage="user$i.asp"
			return
		fi
	done
	MyPage="none"
}

Get_spdMerlin_UI(){
	if [ -f /www/AdaptiveQoS_ROG.asp ]; then
		echo "AdaptiveQoS_ROG.asp"
	else
		echo "AiMesh_Node_FirmwareUpgrade.asp"
	fi
}

Mount_WebUI(){
	if Firmware_Version_Check "webui" ; then
		Get_WebUI_Page "$SCRIPT_DIR/ntpdstats_www.asp"
		if [ "$MyPage" = "none" ]; then
			Print_Output "true" "Unable to mount $SCRIPT_NAME WebUI page, exiting" "$CRIT"
			exit 1
		fi
		Print_Output "true" "Mounting $SCRIPT_NAME WebUI page as $MyPage" "$PASS"
		cp -f "$SCRIPT_DIR/ntpdstats_www.asp" "$SCRIPT_WEBPAGE_DIR/$MyPage"
		
		if [ ! -f "/tmp/index_style.css" ]; then
			cp -f "/www/index_style.css" "/tmp/"
		fi
		
		if ! grep -q '.menu_Addons' /tmp/index_style.css ; then
			echo ".menu_Addons { background: url(ext/shared-jy/addons.png); }" >> /tmp/index_style.css
		fi
		
		umount /www/index_style.css 2>/dev/null
		mount -o bind /tmp/index_style.css /www/index_style.css
		
		if [ ! -f "/tmp/menuTree.js" ]; then
			cp -f "/www/require/modules/menuTree.js" "/tmp/"
		fi
		
		sed -i "\\~$MyPage~d" /tmp/menuTree.js
		
		if ! grep -q 'menuName: "Addons"' /tmp/menuTree.js ; then
			lineinsbefore="$(( $(grep -n "exclude:" /tmp/menuTree.js | cut -f1 -d':') - 1))"
			sed -i "$lineinsbefore"'i,\n{\nmenuName: "Addons",\nindex: "menu_Addons",\ntab: [\n{url: "ext/shared-jy/redirect.htm", tabName: "Help & Support"},\n{url: "NULL", tabName: "__INHERIT__"}\n]\n}' /tmp/menuTree.js
		fi
		
		if ! grep -q "javascript:window.open('/ext/shared-jy/redirect.htm'" /tmp/menuTree.js ; then
			sed -i "s~ext/shared-jy/redirect.htm~javascript:window.open('/ext/shared-jy/redirect.htm','_blank')~" /tmp/menuTree.js
		fi
		sed -i "/url: \"javascript:window.open('\/ext\/shared-jy\/redirect.htm'/i {url: \"$MyPage\", tabName: \"NTP Daemon\"}," /tmp/menuTree.js
		
		umount /www/require/modules/menuTree.js 2>/dev/null
		mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
	else
		Mount_NTPD_WebUI_Old
		Modify_WebUI_File
	fi
}

Mount_NTPD_WebUI_Old(){
	umount /www/Feedback_Info.asp 2>/dev/null
	
	mount -o bind "$SCRIPT_DIR/ntpdstats_www.asp" /www/Feedback_Info.asp
}

Modify_WebUI_File(){
	### menuTree.js ###
	umount /www/require/modules/menuTree.js 2>/dev/null
	tmpfile=/tmp/menuTree.js
	cp "/www/require/modules/menuTree.js" "$tmpfile"
	
	if [ -f "/jffs/scripts/uiDivStats" ]; then
		sed -i '/{url: "Advanced_MultiSubnet_Content.asp", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Advanced_MultiSubnet_Content.asp", tabName: "Diversion Statistics"},' "$tmpfile"
		sed -i '/retArray.push("Advanced_MultiSubnet_Content.asp");/d' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/connmon" ]; then
		sed -i '/{url: "Advanced_Feedback.asp", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Advanced_Feedback.asp", tabName: "Uptime Monitoring"},' "$tmpfile"
		sed -i '/retArray.push("Advanced_Feedback.asp");/d' "$tmpfile"
	fi
	
	if [ -f "/jffs/scripts/spdmerlin" ]; then
		sed -i '/{url: "'"$(Get_spdMerlin_UI)"'", tabName: /d' "$tmpfile"
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "'"$(Get_spdMerlin_UI)"'", tabName: "SpeedTest"},' "$tmpfile"
		sed -i '/retArray.push("'"$(Get_spdMerlin_UI)"'");/d' "$tmpfile"
	fi
	
	sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Feedback_Info.asp", tabName: "NTP Daemon"},' "$tmpfile"
	
	if [ -f /jffs/scripts/custom_menuTree.js ]; then
		mv /jffs/scripts/custom_menuTree.js "$SHARED_DIR/custom_menuTree.js"
	fi
	
	if [ ! -f "$SHARED_DIR/custom_menuTree.js" ]; then
		cp "$tmpfile" "$SHARED_DIR/custom_menuTree.js"
	fi
	
	if ! diff -q "$tmpfile" "$SHARED_DIR/custom_menuTree.js" >/dev/null 2>&1; then
		cp "$tmpfile" "$SHARED_DIR/custom_menuTree.js"
	fi
	
	rm -f "$tmpfile"
	
	mount -o bind "$SHARED_DIR/custom_menuTree.js" "/www/require/modules/menuTree.js"
	### ###
	
	### start_apply.htm ###
	umount /www/start_apply.htm 2>/dev/null
	tmpfile=/tmp/start_apply.htm
	cp "/www/start_apply.htm" "$tmpfile"
	
	if [ -f "/jffs/scripts/uiDivStats" ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Advanced_MultiSubnet_Content.asp") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	if [ -f /jffs/scripts/spdmerlin ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("'"$(Get_spdMerlin_UI)"'") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	if [ -f /jffs/scripts/connmon ]; then
		sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Advanced_Feedback.asp") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	fi
	
	sed -i -e '/else if(current_page.indexOf("Feedback") != -1){/i else if(current_page.indexOf("Feedback_Info.asp") != -1){'"\\r\\n"'setTimeout(getXMLAndRedirect, restart_time*1000);'"\\r\\n"'}' "$tmpfile"
	
	if [ -f /jffs/scripts/custom_start_apply.htm ]; then
		mv /jffs/scripts/custom_start_apply.htm "$SHARED_DIR/custom_start_apply.htm"
	fi
	
	if [ ! -f "$SHARED_DIR/custom_start_apply.htm" ]; then
		cp "/www/start_apply.htm" "$SHARED_DIR/custom_start_apply.htm"
	fi
	
	if ! diff -q "$tmpfile" "$SHARED_DIR/custom_start_apply.htm" >/dev/null 2>&1; then
		cp "$tmpfile" "$SHARED_DIR/custom_start_apply.htm"
	fi
	
	rm -f "$tmpfile"
	
	mount -o bind "$SHARED_DIR/custom_start_apply.htm" /www/start_apply.htm
	### ###
}

NTPD_Customise(){
	/opt/etc/init.d/S77ntpd stop
	rm -f /opt/etc/init.d/S77ntpd
	Download_File "$SCRIPT_REPO/S77ntpd" "/opt/etc/init.d/S77ntpd"
	chmod +x /opt/etc/init.d/S77ntpd
	/opt/etc/init.d/S77ntpd start
}

WriteStats_ToJS(){
	echo "function $3(){" > "$2"
	html='document.getElementById("'"$4"'").innerHTML="'
	while IFS='' read -r line || [ -n "$line" ]; do
		html="$html""$line""\\r\\n"
	done < "$1"
	html="$html"'"'
	printf "%s\\r\\n}\\r\\n" "$html" >> "$2"
}

#$1 fieldname $2 tablename $3 frequency (hours) $4 length (days) $5 outputfile $6 outputfrequency $7 sqlfile $8 timestamp
WriteSql_ToFile(){
	timenow="$8"
	earliest="$((24*$4/$3))"
	
	{
		echo ".mode csv"
		echo ".output $5$6.tmp"
	} >> "$7"
	
	{
		echo "SELECT '$1',Min([Timestamp]) ChunkStart, IFNULL(Avg([$1]),'NaN') Value FROM"
		echo "( SELECT NTILE($((24*$4/$3))) OVER (ORDER BY [Timestamp]) Chunk, * FROM $2 WHERE [Timestamp] >= ($timenow - ((60*60*$3)*$earliest))) AS T"
		echo "GROUP BY Chunk"
		echo "ORDER BY ChunkStart;"
	} >> "$7"
	echo "var $1$6""size = 1;" >> "$SCRIPT_DIR/ntpstatsdata.js"
}

Aggregate_Stats(){
	metricname="$1"
	period="$2"
	sed -i '1iMetric,Time,Value' "$CSV_OUTPUT_DIR/$metricname$period.tmp"
	head -c -2 "$CSV_OUTPUT_DIR/$metricname$period.tmp" > "$CSV_OUTPUT_DIR/$metricname$period.htm"
	dos2unix "$CSV_OUTPUT_DIR/$metricname$period.htm"
	cp "$CSV_OUTPUT_DIR/$metricname$period.htm" "$CSV_OUTPUT_DIR/$metricname$period.tmp"
	sed -i '1d' "$CSV_OUTPUT_DIR/$metricname$period.tmp"
	min="$(cut -f3 -d"," "$CSV_OUTPUT_DIR/$metricname$period.tmp" | sort -n | head -1)"
	max="$(cut -f3 -d"," "$CSV_OUTPUT_DIR/$metricname$period.tmp" | sort -n | tail -1)"
	avg="$(cut -f3 -d"," "$CSV_OUTPUT_DIR/$metricname$period.tmp" | sort -n | awk '{ total += $1; count++ } END { print total/count }')"
	{
	echo "var $metricname$period""min = $min;"
	echo "var $metricname$period""max = $max;"
	echo "var $metricname$period""avg = $avg;"
	} >> "$SCRIPT_DIR/ntpstatsdata.js"
}


Generate_NTPStats(){
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	NTP_Firmware_Check
	Create_Dirs
	Create_Symlinks
	
	#shellcheck disable=SC2086
	killall ntp 2>/dev/null
	tmpfile=/tmp/ntp-stats.$$
	ntpq -4 -c rv | awk 'BEGIN{ RS=","}{ print }' > "$tmpfile"
	
	[ -n "$(grep offset "$tmpfile" | awk 'BEGIN{FS="="}{print $2}')" ] && NOFFSET=$(grep offset "$tmpfile" | awk 'BEGIN{FS="="}{print $2}') || NOFFSET=0
	[ -n "$(grep frequency "$tmpfile" | awk 'BEGIN{FS="="}{print $2}')" ] && NFREQ=$(grep frequency "$tmpfile" | awk 'BEGIN{FS="="}{print $2}') || NFREQ=0
	[ -n "$(grep sys_jitter "$tmpfile" | awk 'BEGIN{FS="="}{print $2}')" ] && NSJIT=$(grep sys_jitter "$tmpfile" | awk 'BEGIN{FS="="}{print $2}') || NSJIT=0
	[ -n "$(grep clk_jitter "$tmpfile" | awk 'BEGIN{FS="="}{print $2}')" ] && NCJIT=$(grep clk_jitter "$tmpfile" | awk 'BEGIN{FS="="}{print $2}') || NCJIT=0
	[ -n "$(grep clk_wander "$tmpfile" | awk 'BEGIN{FS="="}{print $2}')" ] && NWANDER=$(grep clk_wander "$tmpfile" | awk 'BEGIN{FS="="}{print $2}') || NWANDER=0
	[ -n "$(grep rootdisp "$tmpfile" | awk 'BEGIN{FS="="}{print $2}')" ] &&  NDISPER=$(grep rootdisp "$tmpfile" | awk 'BEGIN{FS="="}{print $2}') || NDISPER=0
	
	TZ=$(cat /etc/TZ)
	export TZ
	timenow=$(date +"%s")
	timenowfriendly=$(date +"%c")
	
	{
		echo "CREATE TABLE IF NOT EXISTS [ntpstats] ([StatID] INTEGER PRIMARY KEY NOT NULL, [Timestamp] NUMERIC NOT NULL, [Offset] REAL NOT NULL,[Frequency] REAL NOT NULL,[Sys_Jitter] REAL NOT NULL,[Clk_Jitter] REAL NOT NULL,[Clk_Wander] REAL NOT NULL,[Rootdisp] REAL NOT NULL);"
		echo "INSERT INTO ntpstats ([Timestamp],[Offset],[Frequency],[Sys_Jitter],[Clk_Jitter],[Clk_Wander],[Rootdisp]) values($timenow,$NOFFSET,$NSJIT,$NCJIT,$NWANDER,$NFREQ,$NDISPER);"
	} > /tmp/ntp-stats.sql
	
	"$SQLITE3_PATH" "$SCRIPT_DIR/ntpdstats.db" < /tmp/ntp-stats.sql
	
	{
		echo "DELETE FROM [ntpstats] WHERE [Timestamp] < ($timenow - (86400*30));"
	} > /tmp/ntp-stats.sql
	
	"$SQLITE3_PATH" "$SCRIPT_DIR/ntpdstats.db" < /tmp/ntp-stats.sql
	
	rm -f "$SCRIPT_DIR/ntpstatsdata.js"
	rm -f "$CSV_OUTPUT_DIR/"*
	rm -f /tmp/ntp-stats.sql
	
	metriclist="Offset Sys_Jitter Frequency"
	
	for metric in $metriclist; do
		{
			echo ".mode csv"
			echo ".output $CSV_OUTPUT_DIR/$metric""daily.tmp"
			echo "select '$metric',[Timestamp],[$metric] from ntpstats WHERE [Timestamp] >= ($timenow - 86400);"
		} > /tmp/ntp-stats.sql
		
		"$SQLITE3_PATH" "$SCRIPT_DIR/ntpdstats.db" < /tmp/ntp-stats.sql
		echo "var $metric""dailysize = 1;" >> "$SCRIPT_DIR/ntpstatsdata.js"
		Aggregate_Stats "$metric" "daily"
		rm -f "$CSV_OUTPUT_DIR/$metric""daily.tmp"*
		rm -f /tmp/ntp-stats.sql
		
		WriteSql_ToFile "$metric" "ntpstats" 1 7 "$CSV_OUTPUT_DIR/$metric" "weekly" "/tmp/ntp-stats.sql" "$timenow"
		"$SQLITE3_PATH" "$SCRIPT_DIR/ntpdstats.db" < /tmp/ntp-stats.sql
		Aggregate_Stats "$metric" "weekly"
		rm -f "$CSV_OUTPUT_DIR/$metric""weekly.tmp"
		rm -f /tmp/ntp-stats.sql
		
		WriteSql_ToFile "$metric" "ntpstats" 3 30 "$CSV_OUTPUT_DIR/$metric" "monthly" "/tmp/ntp-stats.sql" "$timenow"
		"$SQLITE3_PATH" "$SCRIPT_DIR/ntpdstats.db" < /tmp/ntp-stats.sql
		Aggregate_Stats "$metric" "monthly"
		rm -f "$CSV_OUTPUT_DIR/$metric""monthly.tmp"
		rm -f /tmp/ntp-stats.sql
	done
	
	echo "NTPD Performance Stats generated on $timenowfriendly" > "/tmp/ntpstatstitle.txt"
	WriteStats_ToJS "/tmp/ntpstatstitle.txt" "$SCRIPT_DIR/ntpstatstext.js" "SetNTPDStatsTitle" "statstitle"
	
	rm -f "$tmpfile"
	rm -f "/tmp/ntp-"*".csv"
	rm -f "/tmp/ntp-stats.sql"
	rm -f "/tmp/ntpstatstitle.txt"
}

Shortcut_ntpMerlin(){
	case $1 in
		create)
			if [ -d "/opt/bin" ] && [ ! -f "/opt/bin/$SCRIPT_NAME_LOWER" ] && [ -f "/jffs/scripts/$SCRIPT_NAME_LOWER" ]; then
				ln -s /jffs/scripts/"$SCRIPT_NAME_LOWER" /opt/bin
				chmod 0755 /opt/bin/"$SCRIPT_NAME_LOWER"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$SCRIPT_NAME_LOWER" ]; then
				rm -f /opt/bin/"$SCRIPT_NAME_LOWER"
			fi
		;;
	esac
}

PressEnter(){
	while true; do
		printf "Press enter to continue..."
		read -r "key"
		case "$key" in
			*)
				break
			;;
		esac
	done
	return 0
}

ScriptHeader(){
	clear
	DST_ENABLED="$(nvram get time_zone_dst)"
	if ! Validate_Number "" "$DST_ENABLED" "silent"; then DST_ENABLED=0; fi
	if [ "$DST_ENABLED" -eq "0" ]; then
		DST_ENABLED="Inactive"
	else
		DST_ENABLED="Active"
	fi
	
	DST_SETTING="$(nvram get time_zone_dstoff)"
	DST_SETTING="$(echo "$DST_SETTING" | sed 's/M//g')"
	DST_START="$(echo "$DST_SETTING" | cut -f1 -d",")"
	DST_START="Month $(echo "$DST_START" | cut -f1 -d".") Week $(echo "$DST_START" | cut -f2 -d".") Weekday $(echo "$DST_START" | cut -f3 -d"." | cut -f1 -d"/") Hour $(echo "$DST_START" | cut -f3 -d"." | cut -f2 -d"/")"
	DST_END="$(echo "$DST_SETTING" | cut -f2 -d",")"
	DST_END="Month $(echo "$DST_END" | cut -f1 -d".") Week $(echo "$DST_END" | cut -f2 -d".") Weekday $(echo "$DST_END" | cut -f3 -d"." | cut -f1 -d"/") Hour $(echo "$DST_END" | cut -f3 -d"." | cut -f2 -d"/")"
	
	printf "\\n"
	printf "\\e[1m##########################################################\\e[0m\\n"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##         _           __  __              _  _         ##\\e[0m\\n"
	printf "\\e[1m##        | |         |  \/  |            | |(_)        ##\\e[0m\\n"
	printf "\\e[1m##  _ __  | |_  _ __  | \  / |  ___  _ __ | | _  _ __   ##\\e[0m\\n"
	printf "\\e[1m## | '_ \ | __|| '_ \ | |\/| | / _ \| '__|| || || '_ \  ##\\e[0m\\n"
	printf "\\e[1m## | | | || |_ | |_) || |  | ||  __/| |   | || || | | | ##\\e[0m\\n"
	printf "\\e[1m## |_| |_| \__|| .__/ |_|  |_| \___||_|   |_||_||_| |_| ##\\e[0m\\n"
	printf "\\e[1m##             | |                                      ##\\e[0m\\n"
	printf "\\e[1m##             |_|                                      ##\\e[0m\\n"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##                  %s on %-9s                 ##\\e[0m\\n" "$SCRIPT_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##       https://github.com/jackyaz/ntpMerlin           ##\\e[0m\\n"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##  Config location: %s  ##\\e[0m\\n" "$SCRIPT_DIR/ntp.conf"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##               DST is currently %-8s              ##\\e[0m\\n" "$DST_ENABLED"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##    DST starts on %-33s   ##\\e[0m\\n" "$DST_START"
	printf "\\e[1m##    DST ends on %-33s     ##\\e[0m\\n" "$DST_END"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##########################################################\\e[0m\\n"
	printf "\\n"
}

MainMenu(){
	NTP_REDIRECT_ENABLED=""
	if Auto_NAT check; then
		NTP_REDIRECT_ENABLED="Enabled"
	else
		NTP_REDIRECT_ENABLED="Disabled"
	fi
	printf "1.    Generate updated %s graphs now\\n\\n" "$SCRIPT_NAME"
	printf "2.    Toggle redirect of all NTP traffic to %s\\n      (currently %s)\\n\\n" "$SCRIPT_NAME" "$NTP_REDIRECT_ENABLED"
	printf "3.    Edit %s config\\n\\n" "$SCRIPT_NAME"
	printf "r.    Restart ntpd\\n\\n"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$SCRIPT_NAME"
	printf "e.    Exit %s\\n\\n" "$SCRIPT_NAME"
	printf "z.    Uninstall %s\\n" "$SCRIPT_NAME"
	printf "\\n"
	printf "\\e[1m##########################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_GenerateStats
				fi
				PressEnter
				break
			;;
			2)
				printf "\\n"
				Menu_ToggleNTPRedirect
				PressEnter
				break
			;;
			3)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_Edit
				fi
				break
			;;
			r)
				printf "\\n"
				if Check_Lock "menu"; then
						Menu_RestartNTPD
				fi
				PressEnter
				break
			;;
			u)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_Update
				fi
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				if Check_Lock "menu"; then
					Menu_ForceUpdate
				fi
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n\\e[1mThanks for using %s!\\e[0m\\n\\n\\n" "$SCRIPT_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
					read -r "confirm"
					case "$confirm" in
						y|Y)
							Menu_Uninstall
							exit 0
						;;
						*)
							break
						;;
					esac
				done
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	ScriptHeader
	MainMenu
}

Check_Requirements(){
	CHECKSFAILED="false"
	
	if [ "$(nvram get jffs2_scripts)" -ne 1 ]; then
		nvram set jffs2_scripts=1
		nvram commit
		Print_Output "true" "Custom JFFS Scripts enabled" "$WARN"
	fi
	
	if [ ! -f "/opt/bin/opkg" ]; then
		Print_Output "true" "Entware not detected!" "$ERR"
		CHECKSFAILED="true"
	fi
	
	if ! Firmware_Version_Check "install" ; then
		Print_Output "true" "Unsupported firmware detected - $SCRIPT_NAME requires 384.XX" "$ERR"
		CHECKSFAILED="true"
	fi
	
	NTP_Firmware_Check
	
	if [ "$CHECKSFAILED" = "false" ]; then
		Print_Output "true" "Installing required packages from Entware" "$PASS"
		opkg update
		opkg install sqlite3-cli
		opkg install ntp-utils
		opkg install ntpd
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	Print_Output "true" "Welcome to $SCRIPT_NAME $SCRIPT_VERSION, a script by JackYaz"
	sleep 1
	
	Print_Output "true" "Checking your router meets the requirements for $SCRIPT_NAME"
	
	if ! Check_Requirements; then
		Print_Output "true" "Requirements for $SCRIPT_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		rm -f "/jffs/scripts/$SCRIPT_NAME_LOWER" 2>/dev/null
		exit 1
	fi
	
	Create_Dirs
	Create_Symlinks
	
	Download_File "$SCRIPT_REPO/ntp.conf" "$SCRIPT_DIR/ntp.conf"
	Update_File "ntpdstats_www.asp"
	Update_File "redirect.htm"
	Update_File "addons.png"
	Update_File "chart.js"
	Update_File "chartjs-plugin-zoom.js"
	Update_File "chartjs-plugin-annotation.js"
	Update_File "chartjs-plugin-datasource.js"
	Update_File "hammerjs.js"
	Update_File "moment.js"

	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_ntpMerlin create
	NTPD_Customise
	Generate_NTPStats
}

Menu_Startup(){
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	NTP_Firmware_Check
	Shortcut_ntpMerlin create
	Create_Dirs
	Create_Symlinks
	Mount_WebUI
	Clear_Lock
}

Menu_GenerateStats(){
	Generate_NTPStats
	Clear_Lock "menu"
}

Menu_Edit(){
	texteditor=""
	exitmenu="false"
	
	printf "\\n\\e[1mA choice of text editors is available:\\e[0m\\n"
	printf "1.    nano (recommended for beginners)\\n"
	printf "2.    vi\\n"
	printf "\\ne.    Exit to main menu\\n"
	
	while true; do
		printf "\\n\\e[1mChoose an option:\\e[0m    "
		read -r "editor"
		case "$editor" in
			1)
				texteditor="nano -K"
				break
			;;
			2)
				texteditor="vi"
				break
			;;
			e)
				exitmenu="true"
				break
			;;
			*)
				printf "\\nPlease choose a valid option\\n\\n"
			;;
		esac
	done
	
	if [ "$exitmenu" != "true" ]; then
		oldmd5="$(md5sum "$SCRIPT_DIR/ntp.conf" | awk '{print $1}')"
		$texteditor "$SCRIPT_DIR/ntp.conf"
		newmd5="$(md5sum "$SCRIPT_DIR/ntp.conf" | awk '{print $1}')"
		if [ "$oldmd5" != "$newmd5" ]; then
			/opt/etc/init.d/S77ntpd restart
		fi
	fi
	Clear_Lock "menu"
}

Menu_ToggleNTPRedirect(){
	if Auto_NAT check; then
		Auto_NAT delete
		NTP_Redirect delete
		printf "\\e[1mNTP Redirect has been disabled\\e[0m\\n\\n"
	else
		Auto_NAT create
		NTP_Redirect create
		printf "\\e[1mNTP Redirect has been enabled\\e[0m\\n\\n"
	fi
}

Menu_RestartNTPD(){
	Print_Output "true" "Restarting ntpd..." "$PASS"
	/opt/etc/init.d/S77ntpd restart
	Clear_Lock "menu"
}

Menu_Update(){
	Update_Version "" "menu"
	Clear_Lock "menu"
}

Menu_ForceUpdate(){
	Update_Version force "menu"
	Clear_Lock "menu"
}

Menu_Uninstall(){
	Print_Output "true" "Removing $SCRIPT_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	Auto_NAT delete
	NTP_Redirect delete
	while true; do
		printf "\\n\\e[1mDo you want to delete %s configuration file and stats? (y/n)\\e[0m\\n" "$SCRIPT_NAME"
		read -r "confirm"
		case "$confirm" in
			y|Y)
				rm -rf "$SCRIPT_DIR" 2>/dev/null
				break
			;;
			*)
				break
			;;
		esac
	done
	Shortcut_ntpMerlin delete
	/opt/etc/init.d/S77ntpd stop
	opkg remove --autoremove ntpd
	opkg remove --autoremove ntp-utils
	if Firmware_Version_Check "webui" ; then
		Get_WebUI_Page "$SCRIPT_DIR/ntpdstats_www.asp"
		if [ -n "$MyPage" ] && [ "$MyPage" != "none" ] && [ -f "/tmp/menuTree.js" ]; then
			sed -i "\\~$MyPage~d" /tmp/menuTree.js
			umount /www/require/modules/menuTree.js
			mount -o bind /tmp/menuTree.js /www/require/modules/menuTree.js
			rm -rf "{$SCRIPT_WEBPAGE_DIR:?}/$MyPage"
		fi
	else
		umount /www/Feedback_Info.asp 2>/dev/null
		sed -i '/{url: "Feedback_Info.asp", tabName: "NTP Daemon"}/d' "$SHARED_DIR/custom_menuTree.js"
		umount /www/require/modules/menuTree.js 2>/dev/null
		umount /www/start_apply.htm 2>/dev/null
		if [ ! -f "/jffs/scripts/spdmerlin" ] && [ ! -f "/jffs/scripts/connmon" ]; then
			rm -f "$SHARED_DIR/custom_menuTree.js" 2>/dev/null
			rm -f "$SHARED_DIR/custom_start_apply.htm" 2>/dev/null
		else
			mount -o bind "$SHARED_DIR/custom_menuTree.js" "/www/require/modules/menuTree.js"
			mount -o bind "$SHARED_DIR/custom_start_apply.htm" "/www/start_apply.htm"
		fi
	fi
	rm -f "$SCRIPT_DIR/ntpdstats_www.asp" 2>/dev/null
	rm -rf "$SCRIPT_WEB_DIR" 2>/dev/null
	rm -f "/jffs/scripts/$SCRIPT_NAME_LOWER" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

if [ -z "$1" ]; then
	if [ ! -f /opt/bin/sqlite3 ]; then
		Print_Output "true" "Installing required version of sqlite3 from Entware" "$PASS"
		opkg update
		opkg install sqlite3-cli
	fi
	Create_Dirs
	Create_Symlinks
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_ntpMerlin create
	Update_File "S77ntpd"
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Check_Lock
		Menu_Install
		exit 0
	;;
	startup)
		Check_Lock
		Menu_Startup
		exit 0
	;;
	generate)
		if [ -z "$2" ] && [ -z "$3" ]; then
			Check_Lock
			Generate_NTPStats
			Clear_Lock
		elif [ "$2" = "start" ] && [ "$3" = "$SCRIPT_NAME_LOWER" ]; then
			Check_Lock
			Generate_NTPStats
			Clear_Lock
		fi
		exit 0
	;;
	ntpredirect)
		Print_Output "true" "Sleeping for 5s to allow firewall/nat startup to be completed..." "$PASS"
		sleep 5
		Check_Lock "redirect"
		Auto_NAT create
		NTP_Redirect create
		Clear_Lock "redirect"
		exit 0
	;;
	update)
		Check_Lock
		Update_Version
		Clear_Lock
		exit 0
	;;
	forceupdate)
		Check_Lock
		Update_Version force
		Clear_Lock
		exit 0
	;;
	uninstall)
		Check_Lock
		Menu_Uninstall
		exit 0
	;;
	*)
		Check_Lock
		echo "Command not recognised, please try again"
		Clear_Lock
		exit 1
	;;
esac
