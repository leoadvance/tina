#!/bin/sh

WIFI_START_SCRIPT="/the_path_to/wifi_start.sh"
MIIO_RECV_LINE="/bin/qtapp/miio/miio_recv_line"
MIIO_SEND_LINE="/bin/qtapp/miio/miio_send_line"
WIFI_MAX_RETRY=5
WIFI_RETRY_INTERVAL=3
WIFI_SSID=

# contains(string, substring)
#
# Returns 0 if the specified string contains the specified substring,
# otherwise returns 1.
contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

send_helper_ready() {
    ready_msg="{\"method\":\"_internal.helper_ready\"}"
    echo $ready_msg
    $MIIO_SEND_LINE "$ready_msg"
}

req_wifi_conf_status() {
    REQ_WIFI_CONF_STATUS_RESPONSE="{\"method\":\"_internal.res_wifi_conf_status\",\"params\":1}"
}

request_dinfo() {
#    dinfo_dir=$1
#    dinfo_dir=${dinfo_dir##*params\":\"}
#    dinfo_dir=${dinfo_dir%%\"*}
#    dinfo_file=${dinfo_dir}/device.conf
    dinfo_file="/bin/qtapp/device.conf"	
    dinfo_did=`cat $dinfo_file | grep -v ^# | grep did= | tail -1 | cut -d '=' -f 2`
    dinfo_key=`cat $dinfo_file | grep -v ^# | grep key= | tail -1 | cut -d '=' -f 2`
    dinfo_vendor=`cat $dinfo_file | grep -v ^# | grep vendor= | tail -1 | cut -d '=' -f 2`
    dinfo_mac=`cat $dinfo_file | grep -v ^# | grep mac= | tail -1 | cut -d '=' -f 2`
    dinfo_model=`cat $dinfo_file | grep -v ^# | grep model= | tail -1 | cut -d '=' -f 2`

    RESPONSE_DINFO="{\"method\":\"_internal.response_dinfo\",\"params\":{"
    if [ x$dinfo_did != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO\"did\":$dinfo_did"
    fi
    if [ x$dinfo_key != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"key\":\"$dinfo_key\""
    fi
    if [ x$dinfo_vendor != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"vendor\":\"$dinfo_vendor\""
    fi
    if [ x$dinfo_mac != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"mac\":\"$dinfo_mac\""
    fi
    if [ x$dinfo_model != x ]; then
	RESPONSE_DINFO="$RESPONSE_DINFO,\"model\":\"$dinfo_model\""
    fi
    RESPONSE_DINFO="$RESPONSE_DINFO}}"
}

request_dtoken() {
    dtoken_string=$1
    dtoken_dir=${dtoken_string##*dir\":\"}
    dtoken_dir=${dtoken_dir%%\"*}
    dtoken_token=${dtoken_string##*ntoken\":\"}
    dtoken_token=${dtoken_token%%\"*}

    dtoken_file=${dtoken_dir}/device.token
    dcountry_file=${dtoken_dir}/device.country

    if [ ! -e ${dtoken_dir}/wifi.conf ]; then
	rm -f ${dtoken_file}
    fi

    if [ -e ${dtoken_file} ]; then
	dtoken_token=`cat ${dtoken_file}`
    else
	echo ${dtoken_token} > ${dtoken_file}
    fi
    
    if [ -e ${dcountry_file} ]; then
	dcountry_country=`cat ${dcountry_file}`
    else
    dcountry_country=""
    fi

    RESPONSE_DTOKEN="{\"method\":\"_internal.response_dtoken\",\"params\":\"${dtoken_token}\"}"
    RESPONSE_DCOUNTRY="{\"method\":\"_internal.response_dcountry\",\"params\":\"${dcountry_country}\"}"
}

save_wifi_conf() {
    datadir=$1
    miio_ssid=$2
    miio_passwd=$3
    miio_uid=$4
    miio_country=$5
    if [ x"$miio_passwd" = x ]; then
	miio_key_mgmt="NONE"
    else
	miio_key_mgmt="WPA"
    fi

    echo ssid=\"$miio_ssid\" > $datadir/wifi.conf
    echo psk=\"$miio_passwd\" >> $datadir/wifi.conf
    echo key_mgmt=$miio_key_mgmt >> $datadir/wifi.conf
    echo uid=$miio_uid >> $datadir/wifi.conf
    echo $miio_uid > $datadir/device.uid
    echo $miio_country > $datadir/device.country
}

clear_wifi_conf() {
    datadir=$1
    rm -f $datadir/wifi.conf
    rm -f $datadir/device.uid
    rm -f $datadir/device.country
}

sanity_check() {
	echo "sanity_check"
}

main() {
    while true; do
	BUF=`$MIIO_RECV_LINE`
	if [ $? -ne 0 ]; then
	    sleep 1;
	    continue
	fi
	if contains "$BUF" "_internal.info"; then
	    ip=${STRING##*ip_address=}
	    ip=`echo ${ip} | cut -d ' ' -f 1`
	    echo "ip: $ip"

	    STRING=`ifconfig ${ifname}`

	    netmask=${STRING##*Mask:}
	    netmask=`echo ${netmask} | cut -d ' ' -f 1`
	    echo "netmask: $netmask"

	    gw=`route -n|grep 'UG'|tr -s ' ' | cut -f 2 -d ' '`
	    echo "gw: $gw"

	    # get vendor and then version
	    vendor=`grep "vendor" /etc/miio/device.conf | cut -f 2 -d '=' | tr '[:lower:]' '[:upper:]'`
	    sw_version=`grep "${vendor}_VERSION" /etc/os-release | cut -f 2 -d '='`
	    if [ -z $sw_version ]; then
		sw_version="unknown"
	    fi

	    msg="{\"method\":\"_internal.info\",\"partner_id\":\"\",\"params\":{\
\"hw_ver\":\"Linux\",\"fw_ver\":\"$sw_version\",\
\"ap\":{\
 \"ssid\":\"\",\"bssid\":\"\"\
},\
\"netif\":{\
 \"localIp\":\"$ip\",\"mask\":\"$netmask\",\"gw\":\"$gw\"\
}}}"

	    echo $msg
	    $MIIO_SEND_LINE "$msg"
	elif contains "$BUF" "_internal.req_wifi_conf_status"; then
	    echo "Got _internal.req_wifi_conf_status"
	    req_wifi_conf_status "$BUF"
	    echo $REQ_WIFI_CONF_STATUS_RESPONSE
	    $MIIO_SEND_LINE "$REQ_WIFI_CONF_STATUS_RESPONSE"
	elif contains "$BUF" "_internal.wifi_start"; then
	    wificonf_dir2=${BUF##*\"datadir\":\"}
	    wificonf_dir2=${wificonf_dir2%%\"*}
	    miio_ssid=${BUF##*\"ssid\":\"}
	    miio_ssid=${miio_ssid%%\",\"passwd\":\"*}
	    miio_passwd=${BUF##*\",\"passwd\":\"}
	    miio_passwd=${miio_passwd%%\",\"uid\":\"*}
	    miio_uid=${BUF##*\",\"uid\":\"}
	    miio_uid=${miio_uid%%\"*}
	    miio_country=${BUF##*\",\"country_domain\":\"}
	    miio_country=${miio_country%%\"*}

	    save_wifi_conf "$wificonf_dir2" "$miio_ssid" "$miio_passwd" "$miio_uid" "$miio_country"

	    CMD=$WIFI_START_SCRIPT
	    RETRY=1
	    WIFI_SUCC=1
	    until [ $RETRY -gt $WIFI_MAX_RETRY ]
	    do
		WIFI_SUCC=1
		echo "Retry $RETRY: CMD=${CMD}"
		${CMD} && break
		WIFI_SUCC=0

		if [ $WIFI_MAX_RETRY -eq 1 ]; then
		   break
		fi
		let RETRY=$RETRY+1
		sleep $WIFI_RETRY_INTERVAL
	    done

	    if [ $WIFI_SUCC -eq 1 ]; then
		msg="{\"method\":\"_internal.wifi_connected\"}"
		echo $msg
		$MIIO_SEND_LINE "$msg"
	    else
		clear_wifi_conf $wificonf_dir2
		CMD=$WIFI_START_SCRIPT
		echo "Back to AP mode, CMD=${CMD}"
		${CMD}
		msg="{\"method\":\"_internal.wifi_ap_mode\",\"params\":null}";
		echo $msg
		$MIIO_SEND_LINE "$msg"
	    fi
	elif contains "$BUF" "_internal.request_dinfo"; then
	    echo "Got _internal.request_dinfo"
	    request_dinfo "$BUF"
	    echo $RESPONSE_DINFO
	    $MIIO_SEND_LINE "$RESPONSE_DINFO"
	elif contains "$BUF" "_internal.request_dtoken"; then
	    echo "Got _internal.request_dtoken"
	    request_dtoken "$BUF"
	    echo $RESPONSE_DTOKEN
	    $MIIO_SEND_LINE "$RESPONSE_DTOKEN"
		echo $RESPONSE_DCOUNTRY
	    $MIIO_SEND_LINE "$RESPONSE_DCOUNTRY"
	else
	    echo "Unknown cmd: $BUF"
	fi
    done
}

sanity_check
send_helper_ready
main
