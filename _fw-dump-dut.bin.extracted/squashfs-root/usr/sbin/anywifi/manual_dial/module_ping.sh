#!/bin/sh

. /usr/sbin/anywifi/dial_common.sh

device=$1 	#usbX/ethX

[ ! -d /tmp/module_ping ] && mkdir /tmp/module_ping/
[ -e /tmp/module_ping/${device}.txt ] && exit

txt_change_lock="unlock"
while [ 1 ]
do
	ping_addr1=$(my_uci_get anyos_netwatchdog.device.detect_host1)
	[ "$ping_addr1" == "" ] && ping_addr1="114.114.114.114"

	ping_addr2=$(my_uci_get anyos_netwatchdog.device.detect_host2)
	[ "$ping_addr2" == "" ] && ping_addr2="223.5.5.5"

	ping -I $device -c 1 -w 3 -W 3 -s 0 $ping_addr1 > /dev/null 2>&1
	ret1=$?

	ping -I $device -c 1 -w 3 -W 3 -s 0 $ping_addr2 > /dev/null 2>&1
	ret2=$?

	if [ "$ret1" == "0" -o "$ret2" == "0" ];then
		timestamp="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
		echo "$device 4gwan $timestamp on" > /tmp/module_ping/${device}.txt
		txt_change_lock="unlock"
		sleep 29
	else
		timestamp="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
		if [ "$txt_change_lock" == unlock ] || [ ! -e /tmp/module_ping/${device}.txt ];then
			echo "$device 4gwan $timestamp off" > /tmp/module_ping/${device}.txt
		fi
		txt_change_lock="lock"
	fi
	sleep 1
done

