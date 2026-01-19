#!/bin/sh

[[ "$(pidof ${0##*/} | wc -w)" -gt "2" ]] && echo "Already running ..." && return 2

. /usr/sbin/anywifi/dial_common.sh

get_module_type=$(cat /tmp/mobile_module_name.txt | awk -F ' ' '{print $1}')
driver="$(cat /tmp/mobile_module_name.txt | awk -F ' ' '{print $5}')"
[ -f /usr/sbin/anywifi/sig_restart_module.sh ] && /usr/sbin/anywifi/sig_restart_module.sh && sleep 12
case $get_module_type in
Yuge_AC)
	killall_process yuge_ac
	/usr/sbin/anywifi/manual_dial/yuge_ac &
	debug_echo "Yuge-AC module dial..."
;;
Yuge_CLM920)
	killall_process yuge_clm920
	/usr/sbin/anywifi/manual_dial/yuge_clm920 &
	debug_echo "Yuge_CLM920 module dial..."
;;
sim7600)
	killall_process sim7600
	/usr/sbin/anywifi/manual_dial/sim7600 &
	debug_echo "sim7600 module dial..."
;;
U8300W)
	killall_process u8300w
	/usr/sbin/anywifi/manual_dial/u8300w &
	debug_echo "u8300w module dial..."
;;
ec200t)
	killall_process quectel_ec200t_cn
	/usr/sbin/anywifi/manual_dial/quectel_ec200t_cn &
	debug_echo "EC200T-cn module dial..."
;;
ec200u)
	killall_process quectel_ec200u
	/usr/sbin/anywifi/manual_dial/quectel_ec200u &
	debug_echo "EC200U-CN module dial..."
;;
ec200a)
	killall_process quectel_ec200a
	/usr/sbin/anywifi/manual_dial/quectel_ec200a &
	debug_echo "EC200A module dial..."
;;
ML7820)
	killall_process ML7820_diag
	/usr/sbin/anywifi/manual_dial/ML7820_diag &
	debug_echo "ML7820_diag module"
;;
5GT_W)
	killall_process T_W_diag
	/usr/sbin/anywifi/manual_dial/T_W_diag &
	debug_echo "T&W 5G module"
	;;
5Ghuawei)
	killall_process huawei_mh5000_diag
	/usr/sbin/anywifi/manual_dial/huawei_mh5000_diag &
	debug_echo "huawei MH5000 module"
	break
;;
5GF03x)
	killall_process f03x_mobile
	/usr/sbin/anywifi/manual_dial/f03x_mobile &
	debug_echo "f03x_mobile module"
;;
5Grm500)
#	rmmod GobiNet
#	rmmod /lib/modules/4.19.88/qmi_wwan_q.ko
#	sleep 3
#	insmod /lib/modules/4.19.88/qmi_wwan_q.ko
#	sleep 3
	killall_process quectel_5Grm500 &
	sleep 1
	/usr/sbin/anywifi/manual_dial/quectel_5Grm500 &
	break
;;
5Grm500u)
	killall_process quectel_5Grm500u &
	sleep 1
	/usr/sbin/anywifi/manual_dial/quectel_5Grm500u &
	break
;;
5Gfm150)
	# rmmod GobiNet_fib 2>&1 > /dev/null
	killall_process fibocom_fm150
	debug_echo "fm150 module driver is $driver"
	# if [ "$driver" == "cdc_ether" ];then
		gtusbmode="$(at-cmd /dev/ttyUSB1 at+gtusbmode? | sed -n '2p' | awk -F ': ' '{print $2}' | tr -d '\r')"
		if [ "$gtusbmode" != "18" ];then
			at-cmd /dev/ttyUSB1 at+gtusbmode=18
			at-cmd /dev/ttyUSB1 at+cfun=15
			sleep 10
	#		logger "fibcom module GTUSBMODE!=18, reboot"
	#		reboot
		fi
		/usr/sbin/anywifi/manual_dial/fibocom_fm150 &
	# else
		# insmod GobiNet_fib 2>&1 > /dev/null
		# killall_process fibocom_fm150_GobiNet
		# sleep 1
		# /usr/sbin/anywifi/manual_dial/fibocom_fm150_GobiNet &
	# fi
	break
;;
FG621)
	debug_echo "fibocom_FG621 module"
	killall_process fibocom_FG621
	gtusbmode="$(at-cmd /dev/ttyUSB0 at+gtusbmode? | sed -n '2p' | awk -F ': ' '{print $2}' | tr -d '\r')"
	if [ "$gtusbmode" != "34" ];then
		at-cmd /dev/ttyUSB0 at+gtusbmode=34
		at-cmd /dev/ttyUSB0 at+cfun=15
	fi
	sleep 1
	/usr/sbin/anywifi/manual_dial/fibocom_FG621 &
	break
;;
EM12_G)
	mode="$(at-cmd /dev/ttyUSB2 at+qcfg=\"usbnet\" | sed -n '2p' | cut -d ',' -f2 | tr -d '\r')"
	if [ "$mode" == "1" ] || [ "$mode" == "2" ];then
		at-cmd /dev/ttyUSB2 at+qcfg=\"usbnet\",0
	fi
	debug_echo "EM12_G module"
	killall_process quectel-CM
	killall_process quectel_ec20_ec25
	sleep 1
	/usr/sbin/anywifi/manual_dial/quectel_ec20_ec25 &
	break
;;
ec20)
	debug_echo "ec20/ec20 module"
	killall_process quectel-CM
	killall_process quectel_ec20_ec25
	sleep 1
	/usr/sbin/anywifi/manual_dial/quectel_ec20_ec25 &
	break
;;	
EM060K)
	debug_echo "EM060K module"
	killall_process quectel-CM
	killall_process quectel_ec20_ec25
	sleep 1
	/usr/sbin/anywifi/manual_dial/quectel_ec20_ec25 &
	break
;;
air720)
	killall_process luat_air720
	sleep 1
	debug_echo "luat air720 module"
	/usr/sbin/anywifi/manual_dial/luat_air720 &
	break
;;	
nl668)
	killall_process fibocom_nl668
	sleep 1
	debug_echo "fibcom nl668 module"
	/usr/sbin/anywifi/manual_dial/fibocom_nl668 &
	break
;;	
l718)
	killall_process fibocom_l718
	sleep 1
	debug_echo "fibcom fibocom_l718 module"
	/usr/sbin/anywifi/manual_dial/fibocom_l718 &
	break
;;
l716)
	killall_process fibocom_l716
	sleep 1
	debug_echo "fibcom fibocom_l716 module"
	/usr/sbin/anywifi/manual_dial/fibocom_l716 &
	break
;;
m8321)
	debug_echo "M8321 module"
	killall_process M8321s_diag
	sleep 1
	/usr/sbin/anywifi/manual_dial/M8321s_diag &
	break
;;	
me909s)
	debug_echo "me909s module"
	killall_process me909s_diag
	sleep 1
	/usr/sbin/anywifi/manual_dial/me909s_diag &
	break
;;
BLM960)
	debug_echo "BLM960 module"
	killall_process yuge_clm920
	/usr/sbin/anywifi/manual_dial/yuge_clm920 &
	debug_echo "BLM960 module dial..."
;;
BLM960_CM)
	debug_echo "BLM960 module change mode"
	killall_process yuge_clm920
	ret="$(at-cmd /dev/ttyUSB2 AT+USBCFG? | '/\+USBCFG\:/{print $2}' | tr -d ' \r')"
	if [ "$ret" != 9025 ];then
		at-cmd /dev/ttyUSB2 AT+USBCFG=9025
		debug_echo "BLM960 module change mode..."
	fi
	/usr/sbin/anywifi/manual_dial/yuge_clm920 &
;;
TM21C)
	debug_echo "TM21C module"
	killall_process TM21C
	/usr/sbin/anywifi/manual_dial/TM21C &
	debug_echo "TM21C module dial..."
;;
*)
	debug_echo "not fount module type"
	break
esac
