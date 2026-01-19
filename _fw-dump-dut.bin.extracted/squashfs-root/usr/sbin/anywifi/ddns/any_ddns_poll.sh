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

log_write(){
	#日志初始化
	local LOG_PATH="$(my_uci_get any_ddns.default.log_path)"
	[ -n "$LOG_PATH" ] || LOG_PATH="/tmp/log/any_ddns_log"
	[ -d "${LOG_PATH%/*}" ] || mkdir -p "${LOG_PATH%/*}"
	#日志最大值100行起
	local log_max_line="$(my_uci_get any_ddns.default.log_max_line)"
	[ "$log_max_line" -ge 100 ] || log_max_line=100
	local log_date="$(date "+%Y-%m-%d %H:%M:%S")"
	#日志以行为单位计入
	local log_content="$1"
	local all_line="$(echo "$log_content" | wc -l)"
	local log_line_tail
	local log_line
	local count=1
	while [ "$count" -le "$all_line" ];do
		log_line_tail="$(echo "$log_content" | awk 'NR=="'"$count"'" {print $0}' | sed "s/.*\r//g")"
		log_line="$log_date $log_line_tail"
		[ -e "$LOG_PATH" ] || echo "$log_date Start logging" > "$LOG_PATH"
		log_num="$(wc -l "$LOG_PATH" | awk '{print $1}')"
		if [ "$log_num" -gt "$log_max_line" ];then
			debug_echo "$LOG_PATH is too big  = $log_num"
			sed -i "1i $log_line" "$LOG_PATH"
			sed -i '101,$d' "$LOG_PATH"
		else
			debug_echo "$LOG_PATH is righet = $log_num"
			sed -i "1i $log_line" "$LOG_PATH"
		fi
		debug_echo "$log_line"
		count="$((count + 1))"
	done
	return 0
}

log_write "any_ddns_poll.sh start running"
update_success=0
while true;do
	#轮询间隔最少600s 获取配置项
	poll_time="$(my_uci_get any_ddns.default.poll_time)"
	[ "$poll_time" -ge 600 ] || poll_time=600
	services="$(my_uci_get any_ddns.default.services)"
	username="$(my_uci_get any_ddns.default.username)"
	password="$(my_uci_get any_ddns.default.password)"
	domain="$(my_uci_get any_ddns.default.domain)"
	enabled="$(my_uci_get any_ddns.default.enabled)"
	enabled="$((enabled ^ 0))"

	ip_public_old="${ip_public-NOT_HAVE_IP}"
	ip_public="$(curl -Lk http://faas.hangzhou.epplink.net/ip 2>/dev/null)"

	if [ "$enabled" == 0 ];then
		log_write "any_ddns_poll.sh is exit"
		update_success=0
		echo "$update_success" > /tmp/any_ddns_stat
		exit
	fi

	url_base="$(awk -F "\"" -v "services=$services" '{if($2==services){print $4}}' /usr/sbin/anywifi/ddns/services)"
	if [ -z "$url_base" ];then
		log_write "services is not supported services=$services"
		log_write "sleep ${poll_time}s"
		update_success=0
		echo "$update_success" > /tmp/any_ddns_stat
		sleep "$poll_time"
		continue
	fi

	#当公网IP发生变化 或上传数据失败的情况上传数据
	if [ "$ip_public_old" != "$ip_public" ] || [ "$update_success" == 0 ];then
		#格式不对忽略IP参数 应用服务器检测到的IP
		ip_public_judge="$(echo "$ip_public" | grep -m 1 -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")"
		if [ -z "$ip_public_judge" ];then
			log_write "ip_public is not supported ip_public=$ip_public,so IP set null"
			url_finished="$(echo "$url_base" | sed -e "s/\[USERNAME\]/$username/g; s/\[PASSWORD\]/$password/g; s/\[DOMAIN\]/$domain/g; s/\[IP\]//g;")"
		elif [ -n "$ip_public_judge" ];then
			url_finished="$(echo "$url_base" | sed -e "s/\[USERNAME\]/$username/g; s/\[PASSWORD\]/$password/g; s/\[DOMAIN\]/$domain/g; s/\[IP\]/$ip_public/g;")"
		fi
		debug_echo "url_finished=$url_finished"
		
		curl_ret="$(curl "$url_finished" 2>/tmp/any_ddns_curl_error)"
		curl_error_ret="$?"
		if [ "$curl_error_ret" != 0 ];then
			log_write "$(cat /tmp/any_ddns_curl_error)"
			update_success=0
		elif [ "$curl_error_ret" == 0 ];then
			RET_REGEX="$(awk -F "\"" -v "services=$services" '{if($2==services){print $6}}' /usr/sbin/anywifi/ddns/services)"
			curl_judge="$(echo "$curl_ret" | grep -E "$RET_REGEX")"
			if [ -n "$curl_judge" ];then
				log_write "SET DDNS SUCCESS : curl_ret=$curl_ret"
				update_success=1
			elif [ -z "$curl_judge" ];then
				log_write "SET DDNS FAILURE : curl_ret=$curl_ret"
				update_success=0
			fi
		fi
	fi
	echo "$update_success" > /tmp/any_ddns_stat
	log_write "sleep ${poll_time}s"
	sleep "$poll_time"
done
