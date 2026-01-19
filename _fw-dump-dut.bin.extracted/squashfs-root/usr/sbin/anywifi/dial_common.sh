#!/bin/sh

debug=$(echo $@ | grep "\-\-debug" | wc -l)
debug_echo(){
	if [[ "$debug" == "1" ]];then
		message="$(date +%s) $1"; echo "$message" 1>&2; logger "$message";
	fi
}

my_uci_get(){
	if [ "$(uci get "$1" 2>&1 | grep "Entry not found" | wc -l)" == "1" ];then
		debug_echo "$1 not found"  1>&2
	else
		echo -n "$(uci get "$1")"
	fi
}

killall_process()
{
	process=$1
	pid_list=$(ps -w | grep -w "$process" | grep -v "grep" | awk '{print $1}')
	for pid in $pid_list
	do
		kill -9 $pid
	done
}

get_rndsi_cdc_netcard_name()
{
        #[    5.894125] cdc_ether 1-1.3:1.4 usb0: register 'cdc_ether' at usb-ehci-platform-1.3, CDC Ethernet Device, 96:91:8e:58
	cdc_msg="$(dmesg | grep "CDC Ethernet Device" | grep -w register)"
	cdc_ret="$(echo "$cdc_msg" | grep "CDC Ethernet Device" | wc -l)"
	if [ "$cdc_ret" -ge "1" ];then
		netcard="$(echo "$cdc_msg" | tail -n 1 | awk -F ']' '{print $2}' | awk '{print $3}' | awk -F ':' '{print $1}' | tr -d '\r')"
		echo $netcard
		return
	fi

	#[   10.334860] rndis_host 1-1.3:1.0 eth2: register 'rndis_host' at usb-ehci-platform-1.3, RNDIS device, 00:a0:c6:00:00:0
	rndis_msg="$(dmesg | grep "RNDIS device")"
	rndis_ret="$(echo "$rndis_msg" | grep "RNDIS device" | wc -l)"
	if [ "$rndis_ret" -ge "1" ];then
		netcard="$(echo "$rndis_msg" | tail -n 1 | awk -F ']' '{print $2}' | awk '{print $3}' | awk -F ':' '{print $1}')"
		echo $netcard
		return
	fi

	qmi_msg="$(dmesg | grep -w "WWAN/QMI device" | wc -l)"
	if [ "$qmi_msg" -ge "1" ];then
		netcard="$(dmesg | grep -w "WWAN/QMI device"| tail -n 1 | awk -F ']' '{print $2}' | awk '{print $3}' | awk -F ':' '{print $1}')"
		echo $netcard
		return
	fi

	gobinet_msg="$(dmesg | grep "GobiNet Ethernet Device" | wc -l)"
	if [ "$gobinet_msg" -ge "1" ];then
		netcard="$(dmesg | grep "GobiNet Ethernet Device" | tail -n 1 | awk -F ': register' '{print $1}' | awk '{print $NF}')"
		echo $netcard
		return
	fi

	cdc_ncm_msg="$(dmesg | grep "CDC NCM" | grep -w register)"
	cdc_ncm_ret="$(echo "$cdc_ncm_msg" | grep "cdc_ncm" | wc -l)"
	if [ "$cdc_ncm_ret" -ge "1" ];then
		netcard="$(echo "$cdc_ncm_msg" | tail -n 1 | awk -F ']' '{print $2}' | awk -F ': register' '{print $1}' | awk '{print $NF}')"
		echo $netcard
		return
	fi

	simcom_wwan_msg="$(dmesg | grep "wwan" | grep -w register)"
	simcom_wwan_ret="$(echo "$simcom_wwan_msg" | grep "wwan" | wc -l)"
	if [ "$simcom_wwan_ret" -ge "1" ];then
		netcard="$(echo "$simcom_wwan_msg" | tail -n 1 | awk -F ']' '{print $2}' | awk -F ': register' '{print $1}' | awk '{print $NF}')"
		echo $netcard
		return
	fi

	echo "none"
}

network_provider(){

	network_provider="$1"

	case $network_provider in
	46001)
		network_provider="China Unicom"
	;;
	46006)
		network_provider="China Unicom"
	;;
	46000)
		network_provider="China Mobile"
	;;
	46002)
		network_provider="China Mobile"
	;;
	46007)
		network_provider="China Mobile"
	;;
	46020)
		network_provider="China Mobile"
	;;
	46003)
		network_provider="China Telecom"
	;;
	46005)
		network_provider="China Telecom"
	;;
	46011)
		network_provider="China Telecom"
	;;
	*)
		network_provider=""
	esac
	echo -n "$network_provider"                                             
}

ping_test(){
	local ping_interface="$1"
	local ping_count="$(my_uci_get anyos_netwatchdog.device.ping_count)"
	[ "$ping_count" -ge 30 ] || ping_count=30
	local max_ping_second="$((ping_count * 2))"

	local timestamp1="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
	local timestamp2=$(cat /tmp/module_ping/${ping_interface}.txt | awk '{print $3}')
	local val=$((timestamp1 - timestamp2))
	local now_ping_status=$(cat /tmp/module_ping/${ping_interface}.txt | awk '{print $4}')

	[ -z "$timestamp2" ] && val="$max_ping_second"
	[ -z "$now_ping_status" ] && now_ping_status=off
	if [ "$val" -ge "$max_ping_second" -a "$now_ping_status" == "off" ];then
		debug_echo "$ping_interface ping fail"
		ret_end=1
	else
		debug_echo "$ping_interface ping success"
		ret_end=0
	fi
	echo "$ret_end"
}

restart_4g_module(){
	local atdev="$1"
	local section="$2"
	ifdown "$section"
	gpio_4g="$(my_uci_get netcard.device.module_gpio)"
	active="$(my_uci_get netcard.device.active)"
	if [ "$gpio_4g" == "" ];then
		debug_echo "use cfun restart_4g_module"
		at-cmd $atdev at+cfun=1,1
		sleep 5
	else
		debug_echo "use gpio restart_4g_module"
		[ -z "$active" ] && active=1
		[ "$active" == "1" ] && value=0
		[ "$active" == "0" ] && value=1
		echo $value > /sys/class/gpio/gpio${gpio_4g}/value
		sleep 5
		echo $active > /sys/class/gpio/gpio${gpio_4g}/value
		sleep 15
	fi
	pid_vid="$(cat /tmp/mobile_module_name.txt | awk '{print $2}')"
	pid_vid_judge="$(lsusb | grep -o "$pid_vid")"
	while [ -z "$pid_vid_judge" ];do
		sleep 5
		pid_vid_judge="$(lsusb | grep -o "$pid_vid")"
	done
	ttyUSB="$(ls /dev/ttyUSB* | wc -l)"
	while [ "$ttyUSB" == "0" ];do
		debug_echo "There is no /dev/ttyUSB*"
		sleep 10
		ttyUSB="$(ls /dev/ttyUSB* | wc -l)"
	done
	ifup "$section"
}

set_firewall(){
	local module_section="$1"
	if [ -n "$module_section" ];then
		firewall_section="$(uci show firewall | sed -n 's/firewall.\(\@zone\[[0-9]\+\]\)\.name='\''wan'\''/\1/p' | tail -1)"
		firewall_section_judge="$(uci -q get firewall.${firewall_section}.network | grep -o "$module_section")"
		if [ -z "$firewall_section_judge" ];then
			uci add_list firewall.${firewall_section}.network="$module_section"
			uci commit firewall
			/etc/init.d/firewall restart
		fi
	fi
}
