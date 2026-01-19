#!/bin/sh
[[ "$(pidof ${0##*/} | wc -w)" -gt "2" ]] && echo "Already running ..." && return 2

. /usr/sbin/anywifi/dial_common.sh

start_dial()
{
	proto="$(uci -q get network.4gwan.proto)"
	ppp_sign="$(awk '{print $5}' /tmp/mobile_module_name.txt)"
	if [ "$proto" == "3g" ] || [ "$ppp_sign" == "ppp" ];then
		debug_echo "ppp dial mode"
		/usr/sbin/anywifi/modules/module_rec
	else
		debug_echo "cdc_ether/rndis/gobinet dial mode"
		/usr/sbin/anywifi/manual_dial/script_dial_entry.sh
	fi
}

export_module_power_gpio()
{
	gpio_4g="$(my_uci_get netcard.device.module_gpio)"
	active="$(my_uci_get netcard.device.active)"
	[ -z "$active" ] && active=1
	echo $gpio_4g > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio${gpio_4g}/direction
	echo $active  > /sys/class/gpio/gpio${gpio_4g}/value
}

module_sim_gpio_init(){
	sim_switch_gpio="$(uci -q get netcard.device.sim_switch_gpio)"
	gpio_default_value="$(uci -q get netcard.device.gpio_default_value)"
	if [ ! -e /sys/class/gpio/gpio$sim_switch_gpio ];then
			echo "$sim_switch_gpio" > /sys/class/gpio/export
			echo "out" > /sys/class/gpio/gpio$sim_switch_gpio/direction
	fi
	echo "$gpio_default_value" > /sys/class/gpio/gpio$sim_switch_gpio/value
	module_sim_led_name="$(my_uci_get anyos.led.module_sim_led_name)"
	for poll_sim_led in $module_sim_led_name
	do
		echo -n "none" > /sys/class/leds/${poll_sim_led}/trigger
	done
}

export_module_power_gpio
[ -n "$(uci -q get netcard.device.sim_switch_gpio)" ] && module_sim_gpio_init

while [ 1 ];
do
	pidvid="$(lsusb | awk '{print $6}')"
	if [ -f /tmp/mobile_module_name.txt ];then
		debug_echo "find module vid/pid and exit"
		start_dial
		exit
	fi
	for id in $pidvid;
	do
		debug_echo "Lsusb vid:pid $id"
		ret="$(grep "$id" /usr/sbin/anywifi/modules/module_list)"
		if [ "$?" == "0" ];then
			ret="$(grep "$id" /usr/sbin/anywifi/modules/module_list | tail -n 1)"
			echo "$ret" > /tmp/mobile_module_name.txt
			start_dial
			exit
		fi
	done

	sleep 10
done

debug_echo "there is not found module vid/pid in module_list"

