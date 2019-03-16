#! /bin/sh

Download_File(){
	/usr/sbin/curl -fsL --retry 3 "$1" -o "$2"
}

RRD_Initialise(){
	if [ ! -f /jffs/scripts/ntpdstats.rrd ]; then
		Download_File "https://raw.githubusercontent.com/jackyaz/ntpdMerlin/master/ntpdstats.xml" "/jffs/scripts/ntpdstats.xml"
		rrdtool restore -f /jffs/scripts/ntpdstats.xml /jffs/scripts/ntpdstats.rrd
		rm -f /jffs/scripts/ntpdstats.xml
	fi
}

Modify_WebUI_File(){
	tmpfile=/tmp/menuTree.js
	
	cp "/www/require/modules/menuTree.js" "$tmpfile"
	
	sed -i '/"Tools_OtherSettings.asp", tabName: "Other Settings"/a {url: "Feedback_Info.asp", tabName: "NTP Daemon"},' "$tmpfile"
	if ! diff -q "$tmpfile" "/jffs/scripts/ntpd_menuTree.js" >/dev/null 2>&1; then
		cp "$tmpfile" "/jffs/scripts/ntpd_menuTree.js"
	fi
	
	umount "/www/require/modules/menuTree.js" 2>/dev/null
	mount -o bind "/jffs/scripts/ntpd_menuTree.js" "/www/require/modules/menuTree.js"
}

Generate_NTPStats(){
	# This function originally written by kvic, updated by Jack Yaz
	# This script is adapted from http://www.wraith.sf.ca.us/ntp
	# The original is part of a set of scripts written by Steven Bjork
	
	RDB=/jffs/scripts/ntpdstats.rrd
	
	#shellcheck disable=SC2086
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
	
	COMMON="-c SHADEA#475A5F -c SHADEB#475A5F -c BACK#475A5F -c CANVAS#92A0A520 -c AXIS#92a0a520 -c FONT#ffffff -c ARROW#475A5F -n TITLE:9 -n AXIS:8 -n LEGEND:9 -w 525 -h 175"
	
	D_COMMON='--start -93525 --x-grid MINUTE:20:HOUR:2:HOUR:4:0:%H:%M'
	W_COMMON='--start -691175 --x-grid HOUR:3:DAY:1:DAY:1:0:%d/%m'
	
	#shellcheck disable=SC2086
	taskset 1 rrdtool graph --imgformat PNG /www/ext/stats-ntp-offset.png \
		$COMMON $D_COMMON \
		--title "Offset (s) - $DATE" \
		DEF:offset="$RDB":offset:LAST \
		CDEF:noffset=offset,1000,/ \
		LINE1.5:noffset#fc8500:"offset" \
		GPRINT:noffset:MIN:"Min\: %3.1lf %s" \
		GPRINT:noffset:MAX:"Max\: %3.1lf %s" \
		GPRINT:noffset:LAST:"Curr\: %3.1lf %s\n" 2> /dev/null
	
	#shellcheck disable=SC2086
	taskset 2 rrdtool graph --imgformat PNG /www/ext/stats-ntp-sysjit.png \
		$COMMON $D_COMMON \
		--title "Jitter (s) - $DATE" \
		DEF:sjit=$RDB:sjit:LAST \
		CDEF:nsjit=sjit,1000,/ \
		DEF:offset=$RDB:offset:LAST \
		CDEF:noffset=offset,1000,/ \
		AREA:nsjit#778787:"jitter" \
		GPRINT:nsjit:MIN:"Min\: %3.1lf %s" \
		GPRINT:nsjit:MAX:"Max\: %3.1lf %s" \
		GPRINT:nsjit:AVERAGE:"Avg\: %3.1lf %s" \
		GPRINT:nsjit:LAST:"Curr\: %3.1lf %s\n" 2> /dev/null
	
	#shellcheck disable=SC2086
	taskset 1 rrdtool graph --imgformat PNG /www/ext/stats-week-ntp-offset.png \
		$COMMON $W_COMMON \
		--title "Offset (s) - $DATE" \
		DEF:offset=$RDB:offset:LAST \
		CDEF:noffset=offset,1000,/ \
		LINE1.5:noffset#fc8500:"offset" \
		GPRINT:noffset:MIN:"Min\: %3.1lf %s" \
		GPRINT:noffset:MAX:"Max\: %3.1lf %s" \
		GPRINT:noffset:LAST:"Curr\: %3.1lf %s\n" 2> /dev/null
	
	#shellcheck disable=SC2086
	taskset 2 rrdtool graph --imgformat PNG /www/ext/stats-week-ntp-sysjit.png \
		$COMMON $W_COMMON --alt-autoscale-max \
		--title "Jitter (s) - $DATE" \
		DEF:sjit=$RDB:sjit:LAST \
		CDEF:nsjit=sjit,1000,/ \
		AREA:nsjit#778787:"jitter" \
		GPRINT:nsjit:MIN:"Min\: %3.1lf %s" \
		GPRINT:nsjit:MAX:"Max\: %3.1lf %s" \
		GPRINT:nsjit:AVERAGE:"Avg\: %3.1lf %s" \
		GPRINT:nsjit:LAST:"Curr\: %3.1lf %s\n" 2> /dev/null
	
	#shellcheck disable=SC2086
	taskset 2 rrdtool graph --imgformat PNG /www/ext/stats-week-ntp-freq.png \
		$COMMON $W_COMMON --alt-autoscale --alt-y-grid \
		--title "Drift (ppm) - $DATE" \
		DEF:freq=$RDB:freq:LAST \
		LINE1.5:freq#778787:"drift (ppm)" \
		GPRINT:freq:MIN:"Min\: %2.2lf" \
		GPRINT:freq:MAX:"Max\: %2.2lf" \
		GPRINT:freq:AVERAGE:"Avg\: %2.2lf" \
		GPRINT:freq:LAST:"Curr\: %2.2lf\n" 2> /dev/null
	
	sed -i "/cmd \/jffs\/scripts\/ntpd\/ntpdstats.sh/d" /tmp/syslog.log-1 /tmp/syslog.log
}

Install(){
	opkg install ntp-utils
	opkg install ntpd
	opkg install rrdtool
	/opt/etc/init.d/S77ntpd stop
	rm -f /opt/etc/init.d/S77ntpd
	
	Download_File "https://raw.githubusercontent.com/jackyaz/ntpdMerlin/master/ntp.conf" "/jffs/configs/ntp.conf"
	Download_File "https://raw.githubusercontent.com/jackyaz/ntpdMerlin/master/S77ntpd" "/opt/etc/init.d/S77ntpd"
	chmod +x /opt/etc/init.d/S77ntpd
	
	Download_File "https://raw.githubusercontent.com/jackyaz/ntpdMerlin/master/ntpdstats_www.asp" "/jffs/scripts/ntpdstats_www.asp"
	umount /www/Feedback_Info.asp 2>/dev/null
	mount -o bind /jffs/scripts/ntpdstats_www.asp /www/Feedback_Info.asp
	
	Modify_WebUI_File
	
	RRD_Initialise
	
	/opt/etc/init.d/S77ntpd start
	
	Generate_NTPStats
}

if [ -z "$1" ]; then
	Generate_NTPStats
elif [ "$1" = "install" ]; then
	Install
else
	exit 1
fi
