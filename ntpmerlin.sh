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
readonly NTPD_NAME="ntpMerlin"
#shellcheck disable=SC2019
#shellcheck disable=SC2018
readonly NTPD_NAME_LOWER=$(echo $NTPD_NAME | tr 'A-Z' 'a-z' | sed 's/d//')
readonly NTPD_VERSION="v1.2.4"
readonly NTPD_BRANCH="develop"
readonly NTPD_REPO="https://raw.githubusercontent.com/jackyaz/ntpMerlin/""$NTPD_BRANCH"
[ -z "$(nvram get odmpid)" ] && ROUTER_MODEL=$(nvram get productid) || ROUTER_MODEL=$(nvram get odmpid)
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
		logger -t "$NTPD_NAME" "$2"
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$NTPD_NAME"
	else
		printf "\\e[1m$3%s: $2\\e[0m\\n\\n" "$NTPD_NAME"
	fi
}

### Code for this function courtesy of https://github.com/decoderman- credit to @thelonelycoder ###
Firmware_Version_Check(){
	echo "$1" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}
############################################################################

### Code for these functions inspired by https://github.com/Adamm00 - credit to @Adamm ###
Check_Lock(){
	if [ -f "/tmp/$NTPD_NAME.lock" ]; then
		ageoflock=$(($(date +%s) - $(date +%s -r /tmp/$NTPD_NAME.lock)))
		if [ "$ageoflock" -gt 120 ]; then
			Print_Output "true" "Stale lock file found (>120 seconds old) - purging lock" "$ERR"
			kill "$(sed -n '1p' /tmp/$NTPD_NAME.lock)" >/dev/null 2>&1
			Clear_Lock
			echo "$$" > "/tmp/$NTPD_NAME.lock"
			return 0
		else
			Print_Output "true" "Lock file found (age: $ageoflock seconds) - stopping to prevent duplicate runs" "$ERR"
			#if [ -z "$1" ]; then
				exit 1
			#else
			#	return 1
			#fi
		fi
	else
		echo "$$" > "/tmp/$NTPD_NAME.lock"
		return 0
	fi
}

Clear_Lock(){
	rm -f "/tmp/$NTPD_NAME.lock" 2>/dev/null
	return 0
}

Update_Version(){
	if [ -z "$1" ]; then
		doupdate="false"
		localver=$(grep "NTPD_VERSION=" /jffs/scripts/"$NTPD_NAME_LOWER" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		/usr/sbin/curl -fsL --retry 3 "$NTPD_REPO/$NTPD_NAME_LOWER.sh" | grep -qF "jackyaz" || { Print_Output "true" "404 error detected - stopping update" "$ERR"; return 1; }
		serverver=$(/usr/sbin/curl -fsL --retry 3 "$NTPD_REPO/$NTPD_NAME_LOWER.sh" | grep "NTPD_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
		if [ "$localver" != "$serverver" ]; then
			doupdate="version"
		else
			localmd5="$(md5sum "/jffs/scripts/$NTPD_NAME_LOWER" | awk '{print $1}')"
			remotemd5="$(curl -fsL --retry 3 "$NTPD_REPO/$NTPD_NAME_LOWER.sh" | md5sum | awk '{print $1}')"
			if [ "$localmd5" != "$remotemd5" ]; then
				doupdate="md5"
			fi
		fi
		
		if [ "$doupdate" = "version" ]; then
			Print_Output "true" "New version of $NTPD_NAME available - updating to $serverver" "$PASS"
		elif [ "$doupdate" = "md5" ]; then
			Print_Output "true" "MD5 hash of $NTPD_NAME does not match - downloading updated $serverver" "$PASS"
		fi
			
		Update_File "S77ntpd"
		Update_File "ntp.conf"
		Update_File "ntpdstats_www.asp"
		Modify_WebUI_File
		
		if [ "$doupdate" != "false" ]; then
			/usr/sbin/curl -fsL --retry 3 "$NTPD_REPO/$NTPD_NAME_LOWER.sh" -o "/jffs/scripts/$NTPD_NAME_LOWER" && Print_Output "true" "$NTPD_NAME successfully updated"
			chmod 0755 "/jffs/scripts/$NTPD_NAME_LOWER"
			Clear_Lock
			/jffs/scripts/"$NTPD_NAME_LOWER" generate
			exit 0
		else
			Print_Output "true" "No new version - latest is $localver" "$WARN"
			Clear_Lock
		fi
	fi
	
	case "$1" in
		force)
			serverver=$(/usr/sbin/curl -fsL --retry 3 "$NTPD_REPO/$NTPD_NAME_LOWER.sh" | grep "NTPD_VERSION=" | grep -m1 -oE 'v[0-9]{1,2}([.][0-9]{1,2})([.][0-9]{1,2})')
			Print_Output "true" "Downloading latest version ($serverver) of $NTPD_NAME" "$PASS"
			Update_File "S77ntpd"
			Update_File "ntp.conf"
			Update_File "ntpdstats_www.asp"
			Modify_WebUI_File
			/usr/sbin/curl -fsL --retry 3 "$NTPD_REPO/$NTPD_NAME_LOWER.sh" -o "/jffs/scripts/$NTPD_NAME_LOWER" && Print_Output "true" "$NTPD_NAME successfully updated"
			chmod 0755 "/jffs/scripts/$NTPD_NAME_LOWER"
			Clear_Lock
			/jffs/scripts/"$NTPD_NAME_LOWER" generate
			exit 0
		;;
	esac
}
############################################################################

Update_File(){
	if [ "$1" = "S77ntpd" ]; then
		tmpfile="/tmp/$1"
		Download_File "$NTPD_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "/opt/etc/init.d/$1" >/dev/null 2>&1; then
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			NTPD_Customise
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "ntp.conf" ]; then
		tmpfile="/tmp/$1"
		Download_File "$NTPD_REPO/$1" "$tmpfile"
		if [ -f "/jffs/configs/$1.default" ]; then
			if ! diff -q "$tmpfile" "/jffs/configs/$1.default" >/dev/null 2>&1; then
				Download_File "$NTPD_REPO/$1" "/jffs/configs/$1.default"
				Print_Output "true" "New default version of $1 downloaded to /jffs/configs/$1.default, please compare against your /jffs/configs/$1" "$PASS"
			fi
		else
			Download_File "$NTPD_REPO/$1" "/jffs/configs/$1.default"
			Print_Output "true" "/jffs/configs/$1.default does not exist, downloading now. Please compare against your /jffs/configs/$1" "$PASS"
		fi
		rm -f "$tmpfile"
	elif [ "$1" = "ntpdstats_www.asp" ]; then
		tmpfile="/tmp/$1"
		Download_File "$NTPD_REPO/$1" "$tmpfile"
		if ! diff -q "$tmpfile" "/jffs/scripts/$1" >/dev/null 2>&1; then
			Print_Output "true" "New version of $1 downloaded" "$PASS"
			rm -f "/jffs/scripts/$1"
			Mount_NTPD_WebUI
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

Auto_ServiceEvent(){
	case $1 in
		create)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/service-event)
				# shellcheck disable=SC2016
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$NTPD_NAME_LOWER generate"' "$1" "$2" &'' # '"$NTPD_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$NTPD_NAME"'/d' /jffs/scripts/service-event
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					# shellcheck disable=SC2016
					echo "/jffs/scripts/$NTPD_NAME_LOWER generate"' "$1" "$2" &'' # '"$NTPD_NAME" >> /jffs/scripts/service-event
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/service-event
				echo "" >> /jffs/scripts/service-event
				# shellcheck disable=SC2016
				echo "/jffs/scripts/$NTPD_NAME_LOWER generate"' "$1" "$2" &'' # '"$NTPD_NAME" >> /jffs/scripts/service-event
				chmod 0755 /jffs/scripts/service-event
			fi
		;;
		delete)
			if [ -f /jffs/scripts/service-event ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/service-event)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$NTPD_NAME"'/d' /jffs/scripts/service-event
				fi
			fi
		;;
	esac
}

Auto_Startup(){
	case $1 in
		create)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/services-start)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$NTPD_NAME_LOWER startup"' # '"$NTPD_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$NTPD_NAME"'/d' /jffs/scripts/services-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$NTPD_NAME_LOWER startup"' # '"$NTPD_NAME" >> /jffs/scripts/services-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/services-start
				echo "" >> /jffs/scripts/services-start
				echo "/jffs/scripts/$NTPD_NAME_LOWER startup"' # '"$NTPD_NAME" >> /jffs/scripts/services-start
				chmod 0755 /jffs/scripts/services-start
			fi
		;;
		delete)
			if [ -f /jffs/scripts/services-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/services-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$NTPD_NAME"'/d' /jffs/scripts/services-start
				fi
			fi
		;;
	esac
}

Auto_NAT(){
	case $1 in
		create)
			if [ -f /jffs/scripts/nat-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/nat-start)
				STARTUPLINECOUNTEX=$(grep -cx "/jffs/scripts/$NTPD_NAME_LOWER ntpredirect"' # '"$NTPD_NAME" /jffs/scripts/nat-start)
				
				if [ "$STARTUPLINECOUNT" -gt 1 ] || { [ "$STARTUPLINECOUNTEX" -eq 0 ] && [ "$STARTUPLINECOUNT" -gt 0 ]; }; then
					sed -i -e '/# '"$NTPD_NAME"'/d' /jffs/scripts/nat-start
				fi
				
				if [ "$STARTUPLINECOUNTEX" -eq 0 ]; then
					echo "/jffs/scripts/$NTPD_NAME_LOWER ntpredirect"' # '"$NTPD_NAME" >> /jffs/scripts/nat-start
				fi
			else
				echo "#!/bin/sh" > /jffs/scripts/nat-start
				echo "" >> /jffs/scripts/nat-start
				echo "/jffs/scripts/$NTPD_NAME_LOWER ntpredirect"' # '"$NTPD_NAME" >> /jffs/scripts/nat-start
				chmod 0755 /jffs/scripts/nat-start
			fi
		;;
		delete)
			if [ -f /jffs/scripts/nat-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/nat-start)
				
				if [ "$STARTUPLINECOUNT" -gt 0 ]; then
					sed -i -e '/# '"$NTPD_NAME"'/d' /jffs/scripts/nat-start
				fi
			fi
		;;
		check)
			if [ -f /jffs/scripts/nat-start ]; then
				STARTUPLINECOUNT=$(grep -c '# '"$NTPD_NAME" /jffs/scripts/nat-start)
				
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
			STARTUPLINECOUNT=$(cru l | grep -c "$NTPD_NAME")
			
			if [ "$STARTUPLINECOUNT" -eq 0 ]; then
				cru a "$NTPD_NAME" "*/5 * * * * /jffs/scripts/$NTPD_NAME_LOWER generate"
			fi
		;;
		delete)
			STARTUPLINECOUNT=$(cru l | grep -c "$NTPD_NAME")
			
			if [ "$STARTUPLINECOUNT" -gt 0 ]; then
				cru d "$NTPD_NAME"
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
			iptables -t nat -A PREROUTING -p udp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)"
		;;
		delete)
			iptables -t nat -D PREROUTING -p udp --dport 123 -j DNAT --to "$(nvram get lan_ipaddr)"
		;;
	esac
}

RRD_Initialise(){
	if [ ! -f /jffs/scripts/ntpdstats_rrd.rrd ]; then
		Download_File "$NTPD_REPO/ntpdstats_xml.xml" "/jffs/scripts/ntpdstats_xml.xml"
		rrdtool restore -f /jffs/scripts/ntpdstats_xml.xml /jffs/scripts/ntpdstats_rrd.rrd
		rm -f /jffs/scripts/ntpdstats_xml.xml
	fi
}

Mount_NTPD_WebUI(){
	umount /www/Feedback_Info.asp 2>/dev/null
	if [ ! -f /jffs/scripts/ntpdstats_www.asp ]; then
		Download_File "$NTPD_REPO/ntpdstats_www.asp" "/jffs/scripts/ntpdstats_www.asp"
	fi
	
	mount -o bind /jffs/scripts/ntpdstats_www.asp /www/Feedback_Info.asp
}

Modify_WebUI_File(){
	if [ "$(Firmware_Version_Check "$(nvram get buildno)")" -gt "$(Firmware_Version_Check 380.67)" ]; then
		### menuTree.js ###
		umount /www/require/modules/menuTree.js 2>/dev/null
		tmpfile=/tmp/menuTree.js
		cp "/www/require/modules/menuTree.js" "$tmpfile"
		
		if [ ! -f /jffs/scripts/custom_menuTree.js ]; then
			cp "/www/require/modules/menuTree.js" "/jffs/scripts/custom_menuTree.js"
		fi
		
		if [ -f "/jffs/scripts/connmon" ]; then
			sed -i '/{url: "AdaptiveQoS_ROG.asp", tabName: /d' "$tmpfile"
			sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "AdaptiveQoS_ROG.asp", tabName: "Uptime Monitoring"},' "$tmpfile"
			sed -i '/retArray.push("AdaptiveQoS_ROG.asp");/d' "$tmpfile"
		fi
		
		if [ -f "/jffs/scripts/spdmerlin" ]; then
			sed -i '/{url: "Advanced_Feedback.asp", tabName: /d' "$tmpfile"
			sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Advanced_Feedback.asp", tabName: "SpeedTest"},' "$tmpfile"
			sed -i '/retArray.push("Advanced_Feedback.asp");/d' "$tmpfile"
		fi
		sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Feedback_Info.asp", tabName: "NTP Daemon"},' "$tmpfile"
		if ! diff -q "$tmpfile" "/jffs/scripts/custom_menuTree.js" >/dev/null 2>&1; then
			cp "$tmpfile" "/jffs/scripts/custom_menuTree.js"
		fi
		
		rm -f "$tmpfile"
		
		mount -o bind "/jffs/scripts/custom_menuTree.js" "/www/require/modules/menuTree.js"
		### ###
	else
		### state.js ###
		umount /www/state.js 2>/dev/null
		tmpfile=/tmp/state.js
		cp "/www/state.js" "$tmpfile"
		
		if [ ! -f /jffs/scripts/custom_state.js ]; then
			cp "/www/state.js" "/jffs/scripts/custom_state.js"
		fi
		
		if [ -f "/jffs/scripts/spdmerlin" ] && [ -f "/jffs/scripts/connmon" ]; then
			sed -i 's/Other Settings");/Other Settings", "NTP Daemon", "SpeedTest", "Uptime Monitoring");/' "$tmpfile"
			sed -i 's/therSettings.asp");/therSettings.asp", "Feedback_Info.asp", "Advanced_Feedback.asp", "AdaptiveQoS_ROG.asp");/' "$tmpfile"
		elif [ -f "/jffs/scripts/spdmerlin" ]; then
			sed -i 's/Other Settings");/Other Settings", "NTP Daemon", "SpeedTest");/' "$tmpfile"
			sed -i 's/therSettings.asp");/therSettings.asp", "Feedback_Info.asp", "Advanced_Feedback.asp");/' "$tmpfile"
		elif [ -f "/jffs/scripts/connmon" ]; then
			sed -i 's/Other Settings");/Other Settings", "NTP Daemon", "Uptime Monitoring");/' "$tmpfile"
			sed -i 's/therSettings.asp");/therSettings.asp", "Feedback_Info.asp", "AdaptiveQoS_ROG.asp");/' "$tmpfile"
		fi
		
		if [ -f "/jffs/scripts/spdmerlin" ]; then
			sed -i -e '/else if(location.pathname == "\/Advanced_Feedback.asp") {/,+4d' "$tmpfile"
		fi
		
		if ! diff -q "$tmpfile" "/jffs/scripts/custom_state.js" >/dev/null 2>&1; then
			cp "$tmpfile" "/jffs/scripts/custom_state.js"
		fi
		
		rm -f "$tmpfile"
		
		mount -o bind /jffs/scripts/custom_state.js /www/state.js
		### ###
	fi
	
	### start_apply.htm ###
	umount /www/start_apply.htm 2>/dev/null
	tmpfile=/tmp/start_apply.htm
	cp "/www/start_apply.htm" "$tmpfile"
	sed -i -e 's/setTimeout("parent.redirect();", action_wait\*1000);/parent.showLoading(restart_time, "waiting");'"\\r\\n"'setTimeout(function(){ getXMLAndRedirect(); alert("Please force-reload this page (e.g. Ctrl+F5)");}, restart_time\*1000);/' "$tmpfile"

	if [ ! -f /jffs/scripts/custom_start_apply.htm ]; then
		cp "/www/start_apply.htm" "/jffs/scripts/custom_start_apply.htm"
	fi

	if ! diff -q "$tmpfile" "/jffs/scripts/custom_start_apply.htm" >/dev/null 2>&1; then
		cp "$tmpfile" "/jffs/scripts/custom_start_apply.htm"
	fi

	rm -f "$tmpfile"

	mount -o bind /jffs/scripts/custom_start_apply.htm /www/start_apply.htm
	### ###
}

NTPD_Customise(){
	/opt/etc/init.d/S77ntpd stop
	rm -f /opt/etc/init.d/S77ntpd
	Download_File "$NTPD_REPO/S77ntpd" "/opt/etc/init.d/S77ntpd"
	chmod +x /opt/etc/init.d/S77ntpd
	/opt/etc/init.d/S77ntpd start
}

Generate_NTPStats(){
	# This function originally written by kvic, updated by Jack Yaz
	# This script is adapted from http://www.wraith.sf.ca.us/ntp
	# The original is part of a set of scripts written by Steven Bjork
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	
	RDB=/jffs/scripts/ntpdstats_rrd.rrd
	
	#shellcheck disable=SC2086
	killall ntp 2>/dev/null
	ntpq -4 -c rv | awk 'BEGIN{ RS=","}{ print }' >> /tmp/ntp-rrdstats.$$
	
	NOFFSET=$(grep offset /tmp/ntp-rrdstats.$$ | awk 'BEGIN{FS="="}{print $2}')
	NFREQ=$(grep frequency /tmp/ntp-rrdstats.$$ | awk 'BEGIN{FS="="}{print $2}')
	NSJIT=$(grep sys_jitter /tmp/ntp-rrdstats.$$ | awk 'BEGIN{FS="="}{print $2}')
	NCJIT=$(grep clk_jitter /tmp/ntp-rrdstats.$$ | awk 'BEGIN{FS="="}{print $2}')
	NWANDER=$(grep clk_wander /tmp/ntp-rrdstats.$$ | awk 'BEGIN{FS="="}{print $2}')
	NDISPER=$(grep rootdisp /tmp/ntp-rrdstats.$$ | awk 'BEGIN{FS="="}{print $2}')
	
	rrdtool update $RDB N:"$NOFFSET":"$NSJIT":"$NCJIT":"$NWANDER":"$NFREQ":"$NDISPER"
	rm /tmp/ntp-rrdstats.$$
	
	TZ=$(cat /etc/TZ)
	export TZ
	DATE=$(date "+%a %b %e %H:%M %Y")
	
	COMMON="-c SHADEA#475A5F -c SHADEB#475A5F -c BACK#475A5F -c CANVAS#92A0A520 -c AXIS#92a0a520 -c FONT#ffffff -c ARROW#475A5F -n TITLE:9 -n AXIS:8 -n LEGEND:9 -w 650 -h 200"
	
	D_COMMON='--start -86400 --x-grid MINUTE:20:HOUR:2:HOUR:2:0:%H:%M'
	W_COMMON='--start -604800 --x-grid HOUR:3:DAY:1:DAY:1:0:%Y-%m-%d'
	
	mkdir -p "$(readlink /www/ext)"
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/stats-ntp-offset.png \
		$COMMON $D_COMMON \
		--title "Offset - $DATE" \
		--vertical-label "Seconds" \
		DEF:offset="$RDB":offset:LAST \
		CDEF:noffset=offset,1000,/ \
		LINE1.5:noffset#fc8500:"offset (s)" \
		GPRINT:noffset:MIN:"Min\: %3.1lf %s" \
		GPRINT:noffset:MAX:"Max\: %3.1lf %s" \
		GPRINT:noffset:LAST:"Curr\: %3.1lf %s\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/stats-ntp-sysjit.png \
		$COMMON $D_COMMON \
		--title "Jitter - $DATE" \
		--vertical-label "Seconds" \
		DEF:sjit=$RDB:sjit:LAST \
		CDEF:nsjit=sjit,1000,/ \
		AREA:nsjit#778787:"jitter (s)" \
		GPRINT:nsjit:MIN:"Min\: %3.1lf %s" \
		GPRINT:nsjit:MAX:"Max\: %3.1lf %s" \
		GPRINT:nsjit:AVERAGE:"Avg\: %3.1lf %s" \
		GPRINT:nsjit:LAST:"Curr\: %3.1lf %s\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/stats-week-ntp-offset.png \
		$COMMON $W_COMMON \
		--title "Offset - $DATE" \
		--vertical-label "Seconds" \
		DEF:offset=$RDB:offset:LAST \
		CDEF:noffset=offset,1000,/ \
		LINE1.5:noffset#fc8500:"offset (s)" \
		GPRINT:noffset:MIN:"Min\: %3.1lf %s" \
		GPRINT:noffset:MAX:"Max\: %3.1lf %s" \
		GPRINT:noffset:LAST:"Curr\: %3.1lf %s\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/stats-week-ntp-sysjit.png \
		$COMMON $W_COMMON --alt-autoscale-max \
		--title "Jitter - $DATE" \
		--vertical-label "Seconds" \
		DEF:sjit=$RDB:sjit:LAST \
		CDEF:nsjit=sjit,1000,/ \
		AREA:nsjit#778787:"jitter (s)" \
		GPRINT:nsjit:MIN:"Min\: %3.1lf %s" \
		GPRINT:nsjit:MAX:"Max\: %3.1lf %s" \
		GPRINT:nsjit:AVERAGE:"Avg\: %3.1lf %s" \
		GPRINT:nsjit:LAST:"Curr\: %3.1lf %s\n" >/dev/null 2>&1
	
	#shellcheck disable=SC2086
	rrdtool graph --imgformat PNG /www/ext/stats-week-ntp-freq.png \
		$COMMON $W_COMMON --alt-autoscale --alt-y-grid \
		--title "Drift - $DATE" \
		--vertical-label "ppm" \
		DEF:freq=$RDB:freq:LAST \
		LINE1.5:freq#778787:"drift (ppm)" \
		GPRINT:freq:MIN:"Min\: %2.2lf" \
		GPRINT:freq:MAX:"Max\: %2.2lf" \
		GPRINT:freq:AVERAGE:"Avg\: %2.2lf" \
		GPRINT:freq:LAST:"Curr\: %2.2lf\n" >/dev/null 2>&1
}

Shortcut_ntpMerlin(){
	case $1 in
		create)
			if [ -d "/opt/bin" ] && [ ! -f "/opt/bin/$NTPD_NAME_LOWER" ] && [ -f "/jffs/scripts/$NTPD_NAME_LOWER" ]; then
				ln -s /jffs/scripts/"$NTPD_NAME_LOWER" /opt/bin
				chmod 0755 /opt/bin/"$NTPD_NAME_LOWER"
			fi
		;;
		delete)
			if [ -f "/opt/bin/$NTPD_NAME_LOWER" ]; then
				rm -f /opt/bin/"$NTPD_NAME_LOWER"
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
	printf "\\e[1m##                  %s on %-9s                 ##\\e[0m\\n" "$NTPD_VERSION" "$ROUTER_MODEL"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
	printf "\\e[1m##       https://github.com/jackyaz/ntpMerlin           ##\\e[0m\\n"
	printf "\\e[1m##                                                      ##\\e[0m\\n"
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
	printf "1.    Generate updated %s graphs now\\n\\n" "$NTPD_NAME"
	printf "2.    Toggle redirect of all NTP traffic to %s\\n      (currently %s)\\n\\n" "$NTPD_NAME" "$NTP_REDIRECT_ENABLED"
	printf "3.    Edit %s config\\n\\n" "$NTPD_NAME"
	printf "u.    Check for updates\\n"
	printf "uf.   Update %s with latest version (force update)\\n\\n" "$NTPD_NAME"
	printf "e.    Exit %s\\n\\n" "$NTPD_NAME"
	printf "z.    Uninstall %s\\n" "$NTPD_NAME"
	printf "\\n"
	printf "\\e[1m##########################################################\\e[0m\\n"
	printf "\\n"
	
	while true; do
		printf "Choose an option:    "
		read -r "menu"
		case "$menu" in
			1)
				printf "\\n"
				Menu_GenerateStats
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
				Menu_Edit
				break
			;;
			u)
				printf "\\n"
				Menu_Update
				PressEnter
				break
			;;
			uf)
				printf "\\n"
				Menu_ForceUpdate
				PressEnter
				break
			;;
			e)
				ScriptHeader
				printf "\\n\\e[1mThanks for using %s!\\e[0m\\n\\n\\n" "$NTPD_NAME"
				exit 0
			;;
			z)
				while true; do
					printf "\\n\\e[1mAre you sure you want to uninstall %s? (y/n)\\e[0m\\n" "$NTPD_NAME"
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
	
	if [ "$(Firmware_Version_Check "$(nvram get buildno)")" -lt "$(Firmware_Version_Check 384.5)" ] && [ "$(Firmware_Version_Check "$(nvram get buildno)")" -ne "$(Firmware_Version_Check 374.43)" ]; then
		Print_Output "true" "Older Merlin firmware detected - service-event requires 384.5 or later" "$WARN"
		Print_Output "true" "Please update to benefit from $NTPD_NAME stats generation in WebUI" "$WARN"
	elif [ "$(Firmware_Version_Check "$(nvram get buildno)")" -eq "$(Firmware_Version_Check 374.43)" ]; then
		Print_Output "true" "John's fork detected - service-event requires 374.43_32D6j9527 or later" "$WARN"
		Print_Output "true" "Please update to benefit from $NTPD_NAME stats generation in WebUI" "$WARN"
	fi
	
	if [ "$CHECKSFAILED" = "false" ]; then
		return 0
	else
		return 1
	fi
}

Menu_Install(){
	Print_Output "true" "Welcome to $NTPD_NAME $NTPD_VERSION, a script by JackYaz"
	sleep 1
	
	Print_Output "true" "Checking your router meets the requirements for $NTPD_NAME"
	
	if ! Check_Requirements; then
		Print_Output "true" "Requirements for $NTPD_NAME not met, please see above for the reason(s)" "$CRIT"
		PressEnter
		Clear_Lock
		exit 1
	fi
	
	opkg update
	opkg install ntp-utils
	opkg install ntpd
	opkg install rrdtool
	
	Download_File "$NTPD_REPO/ntp.conf" "/jffs/configs/ntp.conf"
	
	Mount_NTPD_WebUI
	
	Modify_WebUI_File
	
	RRD_Initialise
	
	NTPD_Customise
	
	Shortcut_ntpMerlin create
	
	Generate_NTPStats
}

Menu_Startup(){
	Check_Lock
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Mount_NTPD_WebUI
	Modify_WebUI_File
	RRD_Initialise
	Clear_Lock
}

Menu_GenerateStats(){
	Check_Lock
	Generate_NTPStats
	Clear_Lock
}

Menu_Edit(){
	Check_Lock
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
		oldmd5="$(md5sum "/jffs/configs/ntp.conf" | awk '{print $1}')"
		$texteditor /jffs/configs/ntp.conf
		newmd5="$(md5sum "/jffs/configs/ntp.conf" | awk '{print $1}')"
		if [ "$oldmd5" != "$newmd5" ]; then
			/opt/etc/init.d/S77ntpd restart
		fi
	fi
	Clear_Lock
}

Menu_ToggleNTPRedirect(){
	Check_Lock
	if Auto_NAT check; then
		Auto_NAT delete
		NTP_Redirect delete
		printf "\\e[1mNTP Redirect has been disabled\\e[0m\\n\\n"
	else
		Auto_NAT create
		NTP_Redirect create
		printf "\\e[1mNTP Redirect has been enabled\\e[0m\\n\\n"
	fi
	Clear_Lock
}

Menu_Update(){
	Check_Lock
	Update_Version
	Clear_Lock
}

Menu_ForceUpdate(){
	Check_Lock
	Update_Version force
	Clear_Lock
}

Menu_Uninstall(){
	Check_Lock
	Print_Output "true" "Removing $NTPD_NAME..." "$PASS"
	Auto_Startup delete 2>/dev/null
	Auto_Cron delete 2>/dev/null
	Auto_ServiceEvent delete 2>/dev/null
	Auto_NAT delete
	NTP_Redirect delete
	while true; do
		printf "\\n\\e[1mDo you want to delete %s configuration file and stats? (y/n)\\e[0m\\n" "$NTPD_NAME"
		read -r "confirm"
		case "$confirm" in
			y|Y)
				rm -f "/jffs/configs/ntp.conf" 2>/dev/null
				rm -f "/jffs/scripts/ntpdstats_rrd.rrd" 2>/dev/null
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
	umount /www/Feedback_Info.asp 2>/dev/null
	sed -i '/{url: "Feedback_Info.asp", tabName: "NTP Daemon"}/d' "/jffs/scripts/custom_menuTree.js"
	umount /www/require/modules/menuTree.js 2>/dev/null
	umount /www/start_apply.htm 2>/dev/null
	if [ ! -f "/jffs/scripts/spdmerlin" ] && [ ! -f "/jffs/scripts/connmon" ]; then
		opkg remove --autoremove rrdtool
		rm -f "/jffs/scripts/custom_menuTree.js" 2>/dev/null
		rm -f "/jffs/scripts/custom_start_apply.htm" 2>/dev/null
	else
		mount -o bind "/jffs/scripts/custom_menuTree.js" "/www/require/modules/menuTree.js"
		mount -o bind "/jffs/scripts/custom_start_apply.htm" "/www/start_apply.htm"
	fi
	rm -f "/jffs/scripts/ntpdstats_www.asp" 2>/dev/null
	rm -f "/jffs/scripts/$NTPD_NAME_LOWER" 2>/dev/null
	Clear_Lock
	Print_Output "true" "Uninstall completed" "$PASS"
}

if [ -z "$1" ]; then
	Check_Lock
	Auto_Startup create 2>/dev/null
	Auto_Cron create 2>/dev/null
	Auto_ServiceEvent create 2>/dev/null
	Shortcut_ntpMerlin create
	Update_File "S77ntpd"
	Clear_Lock
	ScriptHeader
	MainMenu
	exit 0
fi

case "$1" in
	install)
		Menu_Install
		exit 0
	;;
	startup)
		Menu_Startup
		exit 0
	;;
	generate)
		if [ -z "$2" ] && [ -z "$3" ]; then
			Menu_GenerateStats
		elif [ "$2" = "start" ] && [ "$3" = "$NTPD_NAME_LOWER" ]; then
			Menu_GenerateStats
		fi
		exit 0
	;;
	ntpredirect)
		Auto_NAT create
		NTP_Redirect create
		exit 0
	;;
	update)
		Menu_Update
		exit 0
	;;
	forceupdate)
		Menu_ForceUpdate
		exit 0
	;;
	uninstall)
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
