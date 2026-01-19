#!/bin/sh
if [ -e "/var/run/${0##*/}.pid" ] ;then
	if [ -e "/proc/$(cat /var/run/${0##*/}.pid)" ];then
		echo "${0##*/} is already running"
		return 2
	fi
fi
echo "$$" > /var/run/${0##*/}.pid

debug=$(echo $@ | grep "\-\-debug" | wc -l)
debug_echo(){ if [[ "$debug" == "1" ]];then message="$(date +%s) $1"; echo "$message" 1>&2; logger "$message" >/dev/null 2>&1;fi }

my_uci_get(){
		if [ "$(uci get "$1" 2>&1 | grep "Entry not found" | wc -l)" == "1" ];then
				debug_echo "$1 not found"  1>&2
		else
				echo -n "$(uci get "$1")"
		fi
}

killall_process()
{
	local process=$1
	local pid_list=$(ps -ww | grep -w "$process" | grep -v "grep" | awk '{print $1}')
	for pid in $pid_list
	do
		kill -9 $pid
	done
}

sig_restart()
{
        local process=$1
        local pid_list=$(ps -ww | grep -w "$process" | grep -v "grep" | awk '{print $1}')
	debug_echo "$pid_list"
        for pid in $pid_list
        do
                kill -USR1 $pid
        done
}

if [ -n "/tmp/mobile_module_name.txt" ];then
	get_module_type=$(cat /tmp/mobile_module_name.txt | awk -F ' ' '{print $1}')
fi

case $get_module_type in
m8321)
	debug_echo "M8321s_diag module sig_restart"
	sig_restart M8321s_diag
;;
ML7820)
	debug_echo "ML7820_diag module sig_restart"
	sig_restart ML7820_diag
;;
5Gfm150)
	debug_echo "fibocom_fm150 module sig_restart"
	sig_restart fibocom_fm150
;;
l716)
	debug_echo "fibcom fibocom_l716 module sig_restart"
	sig_restart fibocom_l716
;;
l718)
	debug_echo "fibcom fibocom_l718 module sig_restart"
	sig_restart fibocom_l718
;;
nl668)
	debug_echo "fibcom fibocom_nl668 module sig_restart"
	sig_restart fibocom_nl668
;;
air720)
	debug_echo "luat luat_air720 module"
	sig_restart luat_air720
;;
ec200t)
	debug_echo "quectel_ec200t_cn module sig_restart"
	sig_restart quectel_ec200t_cn
;;
ec200u)
	debug_echo "quectel_ec200u module sig_restart"
	sig_restart quectel_ec200u
;;
ec200a)
	debug_echo "quectel_ec200a module sig_restart"
	sig_restart quectel_ec200a
;;
ec20)
	debug_echo "quectel_ec20_ec25 ec20/ec20 module sig_restart"
	killall_process quectel-CM
	sig_restart quectel_ec20_ec25
;;
EM060K)
	debug_echo "EM060K module sig_restart"
	killall_process quectel-CM
	sig_restart quectel_ec20_ec25
;;
EM12_G)
	debug_echo "quectel_ec20_ec25 EM12_G module sig_restart"
	killall_process quectel-CM
	sig_restart quectel_ec20_ec25
;;
U8300W)
	debug_echo "u8300w module sig_restart"
	sig_restart u8300w
;;
Yuge_CLM920)
	debug_echo "Yuge_CLM920 module sig_restart"
	sig_restart yuge_clm920
;;
sim7600)
	debug_echo "sim7600 module sig_restart"
	sig_restart sim7600
;;
Yuge_AC)
	debug_echo "Yuge-AC module sig_restart"
	sig_restart yuge_ac
;;
lm9248)
	debug_echo "lm9248 module sig_restart"
	sig_restart /usr/sbin/anywifi/comgt/lm9248/worker
;;
FG621)
	debug_echo "FG621 module sig_restart"
	sig_restart fibocom_FG621
;;
5Grm500)
	debug_echo "5Grm500 module sig_restart"
	sig_restart quectel_5Grm500
;;
*)
	debug_echo "not fount module type"
	;;
esac
