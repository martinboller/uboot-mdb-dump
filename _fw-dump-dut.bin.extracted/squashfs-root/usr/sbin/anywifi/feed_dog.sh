#!/bin/sh
if [ -e "/var/run/${0##*/}.pid" ] ;then
	if [ -e "/proc/$(cat /var/run/${0##*/}.pid)" ];then
		echo "${0##*/} is already running"
		return 2
	fi
fi
echo "$$" > /var/run/${0##*/}.pid

. /usr/sbin/anywifi/dial_common.sh

model="$(my_uci_get anyversion.device.device_model)"
DogGpio="$(my_uci_get anyversion.device.doggpio)"
DogType="$(my_uci_get anyversion.device.dogtype)"

debug_echo "Device model is $model, DogGpio is $DogGpio, DogType is $DogType"

#不同设备，不同的GPIO变量,定义看门狗的类型,硬件看门狗dogtype=1 软件看门狗dogtype=0
just_device_model_and_dog_stat() {
	[ "$DogType" == 0 ] && return
	[ "$DogGpio" != "" ] && return

	case $model in
		ZbtlinkZBT-WE2416 |\
		ZbtlinkZBT-WE826-Q)
			DogGpio=2
			DogType=1
		;;
		ZBT-WG1608)
			DogGpio=3
			DogType=1
		;;
		ZBT-WE826-WD |\
		ZBT-WE5926-EC |\
		ZBT-WE1026-5G)
			DogGpio=11
			DogType=1
		;;
		ZBT-WE5926 |\
		ZBT-WE5927 |\
		ZBT-WE2802D |\
		ZBT-WE2806 |\
		ZBT-WE5928 |\
		ZBT-WE2806-A |\
		ZBT-WE2808D |\
		ZBT-WE2805 |\
		ZBT-WE2803D)
			DogGpio=37
			DogType=1
		;;
		ZBT-WG3)
			DogGpio=27
			DogType=1
		;;
		ZBT-WE826-E)
			DogGpio=""
			DogType=0
		;;
		*)
			DogGpio=""
			DogType=0
		;;
	esac
}

just_device_model_and_dog_stat
# export watchdog gpio
if [ "$DogType" == "1" ];then
	echo $DogGpio > /sys/class/gpio/export
	echo out > /sys/class/gpio/gpio$DogGpio/direction

	while true
	do
		echo 1 >/sys/class/gpio/gpio$DogGpio/value
		sleep 1
		echo 0 >/sys/class/gpio/gpio$DogGpio/value
		sleep 1
	done
fi
