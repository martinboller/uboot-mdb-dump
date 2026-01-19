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

LOG_PATH=/www/log_list
log_write(){
	log_date="$(date "+%Y-%m-%d %H:%M:%S")"
	log_content="$1"
	log_line="$log_date $log_content"
	[ -e "$LOG_PATH" ] || echo "$log_date sys:\"Start logging\"" > "$LOG_PATH"
	log_num="$(wc -l "$LOG_PATH" | awk '{print $1}')"
	if [ "$log_num" -gt 100 ];then
		debug_echo "$LOG_PATH is too big  = $log_num"
		sed -i "1i $log_line" "$LOG_PATH"
		sed -i '101,$d' "$LOG_PATH"
	else
		debug_echo "$LOG_PATH is righet = $log_num"
		sed -i "1i $log_line" "$LOG_PATH"
	fi
	debug_echo "$log_line"
	return 0
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
	pid_list=$(ps -w | grep "$process" | grep -v "grep" | awk '{print $1}')
	for pid in $pid_list
	do
		kill -9 $pid
	done
}


restart_4g_module() {
	[ -f /usr/sbin/anywifi/sig_restart_module.sh ] && /usr/sbin/anywifi/sig_restart_module.sh
}

uptime1="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"

/usr/sbin/anywifi/feed_dog.sh &

log_content="sys:\"system start\""
log_write "$log_content"

get_interface(){
	local interface
	local iface_tmp
	iface_tmp="$1"
	module_judge="$(echo "$iface_tmp" | sed -n 's/3g-\(4gwan[0-9]*\).*/\1/p')"
	if [ -z "$module_judge" ];then
		case $iface_tmp in
			pppoe-wan)
				interface="wan"
				;;
			l2tp-l2tp)
				interface="l2tp"
				;;
			*)
			interface="$(uci show network | grep "ifname='$iface_tmp'" | grep -vw "wan6" | awk -F "." '{print $2}')"
		esac
	else
		interface="$module_judge"
	fi
	echo "$interface"
}

DogType="$(my_uci_get anyversion.device.dogtype)"
watchdog_time=120
while true
do
	l2tp_route="$(uci -X show network | sed -n 's/network.\(.*\).interface='\'l2tp\''/\1/p')"
	l2tp_route_section="$(uci -X show network | grep "network.$l2tp_route=route")"
	if  [ -n "$(my_uci_get network.l2tp)" ] && [ -n "$l2tp_route_section" ];then
		netstat_old=""
		[ -f /tmp/net_log/netstat~ ] && netstat_old="$(cat /tmp/net_log/netstat~)"
		success_interface_list=""
		ping_success_iface="$(echo "$netstat_old" | sed -n 's/\(.*\)_old = 1/\1/p')"
		for success_iface_tmp in $ping_success_iface
		do
			success_interface="$(get_interface "$success_iface_tmp")"
			success_interface_list="${success_interface} ${success_interface_list}"
		done
		debug_echo "success_interface_list=$success_interface_list"
		l2tp_success_interface="$(echo "$success_interface_list" | grep -E "l2tp")"
		if [ -z "$l2tp_success_interface" ];then
			l2tp_cnt="$((l2tp_cnt + 1))"
		else
			l2tp_cnt=0
		fi
		[ "$l2tp_cnt" -gt 4 ] && /etc/init.d/network restart && l2tp_cnt=0 && debug_echo "l2tp network restart"
	fi

	detect_itv="$(my_uci_get anyos_netwatchdog.device.detect_itv)"
	while  [ -n "$(route -n | grep -w "UG" | grep -E "pptp|l2tp|ath2")" ] || [ "$(uci -q get shadowsocks-libev.hi.mptcp)" == 1 ];
	do
		sleep $detect_itv
		uptime1="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
	done
	authmode="$(cat /proc/authmode)"
	authmode="$((authmode ^ 0))"
	uptime2="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
	debug_echo "detect_itv is $detect_itv ,authmode is $authmode"
	debug_echo "lease time :$(($uptime2 - $uptime1)) uptime2 : $uptime2 uptime1: $uptime1"

	if [ "$(($uptime2 - $uptime1))" -gt "$watchdog_time" ] && [ "$uptime2" -ge 300 ] && [ "$authmode" == 1 ] ;then
		# watchdog_time=120
		action="$(my_uci_get anyos_netwatchdog.device.action)"
		if [ "$action" == "netrestart" ];then
			debug_echo "action is restart network"
			killall_process feed_dog.sh
			log_write "sys:\"watchdog action is restart network\""
			restart_4g_module
			/etc/init.d/network restart
			uptime1="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
		elif [ "$action" == "sysrestart" ];then
			debug_echo "action is system reboot"
			log_write "sys:\"watchdog action is system reboot\""
			restart_4g_module
			if [ "$DogType" == "1" ];then
				killall_process feed_dog.sh
				sleep 600
				continue
			else
				restart_4g_module
				reboot
			fi
		else
			uptime1="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
			debug_echo "action is none , do nothing"
		fi
		sleep $detect_itv
		continue
	fi
	
	#每轮参数重置
	route_head="$(route -n | grep -w "UG" | sed -n '1p' | awk '{print $8}')"
	netstat_old=""
	[ -f /tmp/net_log/netstat~ ] && netstat_old="$(cat /tmp/net_log/netstat~)"
	ping_pri="$(my_uci_get anyos_netwatchdog.device.mobile_priority)"

	if [ -z "$route_head" ];then
		#TODO 网络链接失败 进行下一轮
		debug_echo "have not UG iface,so ping fail,go to the next poll, sleep $detect_itv"
		sleep "$detect_itv"
		continue
	fi

	default_route_interface="$(get_interface "$route_head")"
	default_route_metric="$(my_uci_get network.${default_route_interface}.metric)"

	success_interface_list=""
	ping_success_iface="$(echo "$netstat_old" | sed -n 's/\(.*\)_old = 1/\1/p')"
	for success_iface_tmp in $ping_success_iface
	do
		success_interface="$(get_interface "$success_iface_tmp")"
		success_interface_list="${success_interface} ${success_interface_list}"
	done
	debug_echo "success_interface_list=$success_interface_list"
	success_interface_list="$(echo "$success_interface_list" | sed 's/[ \t]*$//g' | tr "[ ]" "[\n]")"
	if [ -z "$success_interface_list" ];then
		# 网络链接失败 进行下一轮
		debug_echo "all iface ping fail,go to the next poll ,sleep $detect_itv"
		sleep "$detect_itv"
		continue
	fi
	module_success_interface_list="$(echo "$success_interface_list" | grep "4gwan")"
	module_success_interface="$(echo "$success_interface_list" | grep "4gwan" | sed -n 1p)"
	wan_success_interface="$(echo "$success_interface_list" | grep -w "wan")"
	apcli_success_interface="$(echo "$success_interface_list" | grep -w "wwan")"
	ApCliEnable="$(my_uci_get wireless.default_radio0.ApCliEnable)"
	ApCliEnable="$((ApCliEnable ^ 0))"
	
	if [ "$ping_pri" == 1 ];then
	#4g优先
		module_first="$(my_uci_get anyos_netwatchdog.device.module_first)"
		if [ -z "$module_first" ];then
		#只是4g优先
			default_route_success_range="$module_success_interface_list"
			debug_echo "ping_pri=$ping_pri,so first use module"
		elif [ -n "$module_first" ];then
		#确定优先模块
			module_first_interface="$(echo "$success_interface_list" | grep -w "$module_first")"
			default_route_success_range="$module_first_interface"
			debug_echo "module_first=$module_first,so add use $module_first"
		fi
	elif [ "$ping_pri" == 0 ];then
	#非4g优先
		if [ "$ApCliEnable" == 1 ];then
		#存在wifi中继
			if [ -n "$wan_success_interface" ];then
				default_route_success_range="$wan_success_interface $apcli_success_interface"
			else
				default_route_success_range="$apcli_success_interface"
			fi
			debug_echo "ApCliEnable=$ApCliEnable,so first use wifi apcli0"
		else
		#只wan口
			default_route_success_range="$wan_success_interface"
			debug_echo "ping_pri=$ping_pri,so first use wan"
		fi
	fi
	default_route_judge="$(echo "$default_route_success_range" | grep -w "$default_route_interface")"
	if [ -n "$default_route_judge" ];then
	# 规定范围内有ping成功的接口 且是默认路由 ，不动
		debug_echo "default route is right"
	elif [ -z "$default_route_judge" ];then
		if [ -n "$default_route_success_range" ];then
		#规定范围内有ping成功的接口，且不是默认路由，交换metric
			success_head_interface="$(echo "$default_route_success_range" | sed -n 1p)"
			success_head_metric="$(my_uci_get network.${success_head_interface}.metric)"
			debug_echo "default route $default_route_interface metric=$default_route_metric ,$success_head_interface metric=$success_head_metric switch them"
			uci set network.${success_head_interface}.metric="$default_route_metric"
			uci set network.${default_route_interface}.metric="$success_head_metric"
			uci commit network
			ifup "$default_route_interface"
			ifup "$success_head_interface"
		elif [ -z "$default_route_success_range" ];then
		#规定范围内无 ping 成功的接口
			debug_echo "set model is not ping success,so find a ping success interface"
			default_route_stat="$(echo "$netstat_old" | grep -w "${route_head}_old" | awk '{print $3}')"
			default_route_stat="$((default_route_stat ^ 0))"
			if [ "$default_route_stat" == 0 ];then
			#默认路由不通
				#优先使用4g模块
				if [ -n "$module_success_interface" ];then
				#存在4g模块通，交换metric
					module_success_metric="$(my_uci_get network.${module_success_interface}.metric)"
					debug_echo "default route $default_route_interface metric=$default_route_metric ,$module_success_interface metric=$module_success_metric switch them"
					uci set network.${module_success_interface}.metric="$default_route_metric"
					uci set network.${default_route_interface}.metric="$module_success_metric"
					uci commit network
					ifup "$default_route_interface"
					ifup "$module_success_interface"
				elif [ -z "$module_success_interface" ];then
				#4g模块不通，使用wan口或wifi中继
					if [ -n "$wan_success_interface" ];then
					#wan通，交换metric
						wan_metric="$(my_uci_get network.wan.metric)"
						debug_echo "default route $default_route_interface metric=$default_route_metric ,wan metric=$wan_metric switch them"
						uci set network.wan.metric="$default_route_metric"
						uci set network.${default_route_interface}.metric="$wan_metric"
						uci commit network
						ifup "$default_route_interface"
						ifup wan
					elif [ -n "$apcli_success_interface" ];then
					#wwan通，交换metric
						wwan_metric="$(my_uci_get network.wwan.metric)"
						debug_echo "default route $default_route_interface metric=$default_route_metric ,wwan wifi apcli metric=$wwan_metric switch them"
						uci set network.wwan.metric="$default_route_metric"
						uci set network.${default_route_interface}.metric="$wwan_metric"
						uci commit network
						ifup "$default_route_interface"
						ifup wwan
					else
					#wan wwan都不通 网络链接失败 进行下一轮
						debug_echo "wan ping fail,because it's the last interface,go to the next poll ,sleep $detect_itv"
						sleep "$detect_itv"
						continue
					fi
				fi
			elif [ "$default_route_stat" == 1 ];then
			#规定范围内无 ping 成功的接口 且默认路由通
			#只有优先模块ping失败 与 另一个非优先模块ping成功 且默认wan口ping成功 需要调整优先级
				if [ "$ping_pri" == 1 ];then
					if [ -z "$module_first" ];then
					#4g优先 所有模块ping失败 不变
						debug_echo "default route $default_route_interface ping success,module ping fail,so keep the default route"
					elif [ -n "$module_first" ];then
					#模块优先
						if [ "$default_route_interface" == "wan" ];then
							if [ -n "$module_success_interface" ];then
							#只有优先模块ping失败 且 默认wan口ping成功 与 另一个模块ping成功 需要调整优先级
								module_success_metric="$(my_uci_get network.${module_success_interface}.metric)"
								debug_echo "$module_first ping fail,but $module_success_interface ping success,default route is wan"
								debug_echo "default route $default_route_interface metric=$default_route_metric ,-$module_success_interface- metric=$module_success_metric switch them"
								uci set network.${module_success_interface}.metric="$default_route_metric"
								uci set network.${default_route_interface}.metric="$module_success_metric"
								uci commit network
								ifup "$default_route_interface"
								ifup "$module_success_interface"
							else
								#虽然是模块优先 但不存在ping通的模块 不变
								debug_echo "default route $default_route_interface ping success,$module_first ping fail,so keep the default route"
							fi
						else
							#优先模块ping失败 但默认路由是另一个模块 不变
							debug_echo "default route $default_route_interface ping success,$module_first ping fail,so keep the default route"
						fi
					fi
				elif [ "$ping_pri" == 0 ];then
				#wan口优先 wan口ping失败 不变
					debug_echo "default route $default_route_interface ping success,wan ping fail,so keep the default route"
				fi
			fi
		fi
	fi
	[ -n "$(ps -w | grep "feed_dog.sh" | grep -v "grep")"  ] || /usr/sbin/anywifi/feed_dog.sh &
	uptime1="$(cat /proc/uptime | awk '{print $1}' | awk -F '.' '{print $1}')"
	debug_echo "ping success uptime1 update to $uptime1 ,sleep $detect_itv"
	sleep "$detect_itv"
done

