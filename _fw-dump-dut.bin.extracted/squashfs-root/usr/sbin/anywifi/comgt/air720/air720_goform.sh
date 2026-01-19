air720_var() {
#默认返回中文内容
Language(){
	echo -n 'zh-cn';
}

blc_wan_mode(){
	echo -n 'AUTO_PPP'
}

blc_wan_auto_mode(){
	echo -n "AUTO"
}

#单独处理的事件
#ConnectionMode(){
#	echo -n '{"connectionMode":"auto_dial","autoConnectWhenRoaming":"on"}'
#}

autoConnectWhenRoaming(){
	autoConnectWhenRoaming="on"
	echo -n "$autoConnectWhenRoaming"
}

#升级检查，永远都是没有新的固件
upgrade_result(){
	upgrade_result=""
	echo -n "$upgrade_result"
}

#可能的参数值
#modem_sim_undetected
#modem_init_complate

modem_main_state(){
	modem_main_state="modem_sim_undetected"
#	lsdevusb="$(ls /dev/ttyUSB1)"
#	if [ -z "$lsdevusb" ];then
#		modem_main_state=""
#	fi
	sim_status=$(my_uci_get 4gstatus.info.sim_status)                                                                          
	if [ "$sim_status" == "1" ];then                                                                                           
		modem_main_state="modem_init_complete"                                                                             
	fi   
	echo -n "$modem_main_state"
	#echo -n "modem_sim_undetected"
}



pin_status(){
	pin_status=""
	echo -n "$pin_status"
}

puknumber(){
	puknumber="10"
	echo -n "$puknumber"
}

pinnumber(){
	pinnumber="3"
	echo -n "$pinnumber"
}


blc_wan_mode(){
	blc_wan_mode="AUTO"
	echo -n "$blc_wan_mode"
}

blc_wan_auto_mode(){
	blc_wan_auto_mode="AUTO_PPP"
	echo -n "$blc_wan_auto_mode"
}


loginfo(){
	if [ -f /tmp/MW_userAlreadyLogin ];then
		loginfo="ok"
	else
		loginfo=""
	fi
	echo -n "$loginfo"
}

psw_fail_num_str(){
	psw_fail_num_str="5"
	echo -n "$psw_fail_num_str"
}

login_lock_time(){
	login_lock_time="-1"
	echo -n "$login_lock_time"
}

####升级系统相关内容开始 暂定永远不会有新版本存在
fota_new_version_state(){
	fota_new_version_state=""
	fota_new_version_state="check_failed"
	fota_new_version_state="idle"
	fota_new_version_state="$(my_uci_get mifiweb.info.fota_new_version_state)"
	echo -n 'no_new_version'
}

fota_current_upgrade_state(){
	fota_current_upgrade_state=""
	fota_current_upgrade_state="check_complete"
	fota_current_upgrade_state="idle"
	fota_current_upgrade_state="$(my_uci_get mifiweb.info.fota_current_upgrade_state)"
	echo -n "check_complete"
}

fota_upgrade_selector(){
	fota_upgrade_selector="$(my_uci_get mifiweb.info.fota_upgrade_selector)"
	fota_upgrade_selector="none"
	echo -n $fota_upgrade_selector
}

fota_package_already_download(){
	fota_package_already_download=""
	echo "$fota_package_already_download"
}

	


####升级系统相关内容

network_provider(){
	network_provider=""
	network_provider="China Unicom"
	#"FDD LTE","46011","LTE BAND 3",1825
	#+COPS: 0,2,"46001",7
	network_provider="$(my_uci_get 4gstatus.info.sim_cops | awk -F ',' '{print $3}' | tr -d '"')"

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

#是否强制的参数
is_mandatory(){
	is_mandatory=""
	echo -n "$is_mandatory"
}

#m开头始终为0
m_sta_count(){
	m_sta_count="0"
	echo -n "$m_sta_count"
}

##
sta_count(){
	sta_count="$(iwinfo wlan0 assoclist | grep "SNR" | wc -l)"
	if [ -z "$sta_count" ];then
		sta_count="0"
	fi
	echo -n "$sta_count"
}

#移动网络信号强度，暂定5满格
signalbar(){
	signalbar="5"
	echo -n "$signalbar"
}

##
network_type(){
	network_type="Limited Service"
	network_type="LTE"
	#"FDD LTE","46011","LTE BAND 3",1825
	#"CDMA1X AND HDR","46003","CDMA BC0",283
	#"HSPA+","46001","WCDMA2100",10663
	network_type="$(my_uci_get 4gstatus.info.sim_qnwinfo | awk -F ',' '{print $1}' | tr -d '"')"

	case $network_type in
        "FDD LTE")
                network_type="LTE"
        ;;
        "FDDLTE")
                network_type="LTE"
        ;;
        "TDD LTE")
                network_type="LTE"
        ;;
        "TDDLTE")
                network_type="LTE"
        ;;
        "CDMA1X AND HDR")
                network_type="CDMA"
        ;;
        *)
		network_type="GSM"
        ;;
        esac
	echo -n "$network_type"
}

sub_network_type(){
	sub_network_type="Limited Service"
	sub_network_type="FDD_LTE"
	#"CDMA1X AND HDR","46003","CDMA BC0",283
	#^SYSINFO: 2,3,0,17,1,7
    	#sub_network_type="$(my_uci_get 4gstatus.info.sim_qnwinfo | awk -F ',' '{print $1}' | tr -d '"')"
    	sub_network_type="$(my_uci_get 4gstatus.info.sim_sysinfo | awk -F ',' '{print $4}' | tr -d '"')"
	case $sub_network_type in
        "17")
                sub_network_type="LTE"
        ;;
        "FDDLTE")
                sub_network_type="FDD_LTE"
        ;;
        "TDD LTE")
                sub_network_type="TDD_LTE"
        ;;
        "TDDLTE")
                sub_network_type="LTE"
        ;;
        *)
		sub_network_type="NONE"
        ;;
    esac
	echo -n "$sub_network_type"
}

ppp_status(){
	ppp_status="ppp_disconnected"
	if [ "$(uci get anywifi.internet.status)" == "1" ];then
		ppp_status="ppp_connected"
	fi
	echo -n "$ppp_status"
}

ipv6_pdp_type(){
	ipv6_pdp_type=""
	echo -n "$ipv6_pdp_type"
}

pdp_type(){
	pdp_type="IP"
	echo -n "$pdp_type"
}

pdp_select(){
	pdp_select=""
	echo -n "$pdp_select"
}


###网口状态，这里检查ip link状态
rj45_state(){
	# if [ -z "$(ip link show eth1 | grep "UP")" ];then
		# rj45_state=""
	# else
		# rj45_state="working"
	# fi
	# echo -n "$rj45_state"
	echo -n ""
}

#WiFi配置信息部分，其中扩展WiFi内容固定
EX_SSID1(){
	EX_SSID1="MiFi_"
	echo -n "$EX_SSID1"
}

EX_wifi_profile(){
	EX_wifi_profile=""
	echo -n "$EX_wifi_profile"
}


sta_ip_status(){
	sta_ip_status="disconnect"
	echo -n "$sta_ip_status"
}

#不可能启用中继，直接返回未设置
m_ssid_enable(){
	m_ssid_enable="0"
	echo -n "$m_ssid_enable"
}

NoForwarding(){
	NoForwarding="0"
	echo -n "$NoForwarding"
}
m_NoForwarding(){
	m_NoForwarding=""
	echo -n "$m_NoForwarding"
}

m_SSID(){
	m_SSID="MiFi_000305_2"
	echo -n "$m_SSID"
}



m_AuthMode(){
	m_AuthMode="WPA2PSK"
	echo -n "$m_AuthMode"
}

m_EncrypType(){
	m_EncrypType="AES"
	echo -n "$m_EncrypType"
}

HideSSID(){
	hidden="$(uci get wireless.default_radio0.hidden)"
	echo -n "$hidden"
}

m_HideSSID(){
	HideSSID
}


m_WPAPSK1_encode(){
	m_WPAPSK1_encode="MTIzNDU2Nzg="
	echo -n "$WPAPSK1_encode"
}

wifi_cur_state(){
	wifi_cur_state="1"
	echo -n "$wifi_cur_state"
}

#获取SSID1的数据
SSID1(){
	SSID1="MiFi_000305"
	SSID1="$(my_uci_get wireless.default_radio0.ssid)"
	if [ -z "$SSID1" ];then
		SSID1="MiFi_000000"
	fi
	echo -n "$SSID1"
}

AuthMode(){
	AuthMode=$(my_uci_get wireless.default_radio0.encryption)

	case $AuthMode in                             
        "psk2")    
		AuthMode="WPA2PSK"
        ;;                                                   
        "psk-mixed")               
		AuthMode="WPAPSKWPA2PSK"
        ;;
		"none")
		AuthMode="OPEN"
		;;
        *)                         
		AuthMode="WPA2PSK"
        ;;                                         
    esac
	echo -n "$AuthMode"
}

EncrypType(){
	EncrypType="AES"
	echo -n "EncrypType"
}

WPAPSK1_encode(){
	WPAPSK1_encode="MTIzNDU2Nzg="
	WPAPSK1_encode="$(my_uci_get wireless.default_radio0.key)"
	if [ -z "$WPAPSK1_encode" ];then
		WPAPSK1_encode="MTIzNDU2Nzg="
	fi
	WPAPSK1_encode="$(echo $WPAPSK1_encode | base64)"
	echo -n "$WPAPSK1_encode"
}

simcard_roam(){
	simcard_roam="Home"
	echo -n "$simcard_roam"
}

wan_ipaddr(){
	wan_ipaddr="10.126.60.242"
	lc_wan_ifname="$(route | grep default | awk '{print $8}')"
	wan_ipaddr="$(ifconfig $lc_wan_ifname | grep 'inet addr' | awk -F ':' '{print $2}' | awk '{print $1}')"
	if [ -z "$wan_ipaddr" ];then
		wan_ipaddr="0.0.0.0"
	fi
	echo -n "$wan_ipaddr"
}

static_wan_ipaddr(){
	static_wan_ipaddr="0.0.0.0"
	echo -n "$static_wan_ipaddr"
}

ipv6_wan_ipaddr(){
	ipv6_wan_ipaddr=""
	echo -n "$ipv6_wan_ipaddr"
}

mac_address(){
	mac_address=""
	echo -n "$mac_address"
}


#电池状态和电量，永远都是满且没有充电的状态
battery_charging(){
	battery_charging="0"
	echo -n $battery_charging
}

battery_vol_percent(){
	battery_vol_percent="100"
	echo -n "$battery_vol_percent"
}

battery_pers(){
	battery_pers="4"
	echo -n "$battery_pers"
}
###


spn_name_data(){
	spn_name_data=""
	echo -n "$spn_name_data"
}

spn_b1_flag(){
	spn_b1_flag=""
	echo -n "$spn_b1_flag"
}

spn_b2_flag(){
	spn_b2_flag=""
	echo -n "$spn_b2_flag"
}

realtime_time(){
	#4g connected time seconds
	realtime_time="0"
	#realtime_time="$(ubus call network.interface.4gwan status | grep uptime | grep -oE '([0-9]{1,10})')"
	realtime_time="$(cat /proc/uptime | awk -F. '{print $1}')"
	if [ -z "$realtime_time" ];then
		realtime_time="0"
	fi
	echo -n "$realtime_time"
}

##实时流量
realtime_tx_thrpt(){
	realtime_tx_thrpt="0"
	realtime_tx_thrpt="$(my_uci_get mifiweb.info.realtime_tx_thrpt)"
	if [ -z "$realtime_tx_thrpt" ];then
		realtime_tx_thrpt="0"
	fi
	echo -n "$realtime_tx_thrpt"
}

realtime_rx_thrpt(){
	realtime_rx_thrpt="0"
	realtime_rx_thrpt="$(my_uci_get mifiweb.info.realtime_rx_thrpt)"
	if [ -z "$realtime_rx_thrpt" ];then
		realtime_rx_thrpt="0"
	fi
	echo -n "$realtime_rx_thrpt"
}

realtime_tx_bytes(){
	realtime_tx_bytes="0"
	realtime_tx_bytes="$(my_uci_get mifiweb.info.realtime_tx_bytes)"
	if [ -z "$realtime_tx_bytes" ];then
		realtime_tx_bytes="0"
	fi
	echo -n "$realtime_tx_bytes"
}

realtime_rx_bytes(){
	realtime_rx_bytes="0"
	realtime_rx_bytes="$(my_uci_get mifiweb.info.realtime_rx_bytes)"
	if [ -z "$realtime_rx_bytes" ];then
		realtime_rx_bytes="0"
	fi
	echo -n "$realtime_rx_bytes"
}

#暂时不提供流量统计功能，全部值为零
monthly_rx_bytes(){
	monthly_rx_bytes="0"
	echo -n "$monthly_rx_bytes"
}

monthly_tx_bytes(){
	monthly_tx_bytes="0"
	echo -n "$monthly_tx_bytes"
}

traffic_alined_delta(){
	traffic_alined_delta=""
	echo -n "$traffic_alined_delta"
}

monthly_time(){
	monthly_time="0"
	echo -n "$monthly_time"
}

date_month(){
	date_month=""
	echo -n "$data_month"
}


#数据卷部分，不做处理，直接默认值返回
data_volume_alert_percent(){
	echo -n ""
}

data_volume_limit_size(){
	data_volume_limit_size=""
	echo -n "$data_volume_limit_size"
}

data_volume_limit_switch(){
	data_volume_limit_switch="0"
	echo -n $data_volume_limit_switch
}

data_volume_limit_unit(){
	data_volume_limit_unit="0"
	echo -n "$data_volume_limit_unit"
}
##数据卷部分结束


roam_setting_option(){
	roam_setting_option="on"
	echo -n "$roam_setting_option"
}

upg_roam_switch(){
	upg_roam_switch=""
	echo -n "$upg_roam_switch"
}



ssid(){
	ssid=""
}

dial_mode(){
	dial_mode="auto_dial"
	echo -n "$dial_mode"
}

ethwan_mode(){
	ethwan_mode="auto"
	echo -n "$ethwan_mode"
}

default_wan_name(){
	default_wan_name="wan1"
	echo -n $default_wan_name
}

#Group after login :cmd=sms_capacity_info
#sms查询信息
sms_capacity_info(){
	echo -n '{"sms_nv_total":"100","sms_sim_total":"40","sms_nv_rev_total":"2","sms_nv_send_total":"0","sms_nv_draftbox_total":"0","sms_sim_rev_total":"5","sms_sim_send_total":"0","sms_sim_draftbox_total":"0"}'
}

sms_received_flag(){
	echo -n ""
}

###


###Group after login: cmd=sms_cmd_status_info&sms_cmd=1
sms_cmd(){
	sms_cmd="1"
}

sms_cmd_status_result(){
	sms_cmd_status_result="2"
}

sms_nv_total(){
	sms_nv_total="100"
}

sms_sim_total(){
	sms_sim_total="40"
}

sms_nv_rev_total(){
	sms_nv_rev_total="0"
}

sms_nv_send_total(){
	sms_nv_send_total="0"
}

sms_nv_draftbox_total(){
	sms_nv_draftbox_total="0"
}

sms_sim_rev_total(){
	sms_sim_rev_total="0"
}

sms_sim_send_total(){
	sms_sim_send_total="0"
}

sms_sim_draftbox_total(){
	sms_sim_draftbox_total="0"
}

sts_received_flag(){
	sts_received_flag=""
}

sms_unread_num(){
	sms_unread_num="0"
	echo -n "$sms_unread_num"
}

#short_mode medium_mode long_mode
wifi_coverage(){
	wifi_coverage="$(uci get mifiweb.info.wifi_coverage)"
	if [ -z "$wifi_coverage" ];then
		wifi_coverage="long_mode"
	fi
	echo -n "$wifi_coverage"
}

imei(){
	imei="355479026270535"
	imei="$(my_uci_get 4gstatus.info.sim_imei)"
	if [ -z "$imei" ];then
		imei=""
	fi
	echo -n "$imei"
}

rssi(){
	rssi="-89"
	#sim_signal=' 22,99'
	rssi=$(my_uci_get 4gstatus.info.sim_signal | awk -F ',' '{print $1}' | tr -d " " | tr -d "'")
	rssi=$((rssi-82))
	if [ -z "$rssi" ];then
		rssi="-89"
	fi
	echo -n "$rssi"

}

rscp(){
	rscp=""
	#sim_signal=' 22,99'
	rssi=$(my_uci_get 4gstatus.info.sim_signal | awk -F ',' '{print $1}' | tr -d " " | tr -d "'")
	rssi=$((rssi-82))
	rscp=$rssi
	if [ -z "$rssi" ];then
		rscp=""
	fi
	echo -n "$rscp"

}

lte_rsrp(){
	lte_rsrp="-89"
	#sim_signal=' 22,99'
	rssi=$(my_uci_get 4gstatus.info.sim_signal | awk -F ',' '{print $1}' | tr -d " " | tr -d "'")
	rssi=$((rssi-82))
	lte_rscp="$rssi"
	if [ -z "$rssi" ];then
		lte_rscp=""
	fi
	echo -n "$lte_rscp"
}

imsi(){
	imsi=""
	imsi=$(my_uci_get 4gstatus.info.sim_imsi)
	if [ -z "$imsi" ];then
		imsi=""
	fi
	echo -n "$imsi"
}

sim_imsi(){
	sim_imsi="460010028209239"
	sim_imsi=$(my_uci_get 4gstatus.info.sim_imsi)
	if [ -z "$sim_imsi" ];then
		sim_imsi=""
	fi
	echo -n "$sim_imsi"
}

msisdn(){
	msisdn="+8613280027851"
	msisdn=$(my_uci_get 4gstatus.info.sim_iccid)
	if [ -z "$msisdn" ];then
		msisdn=""
	fi
	echo -n "$msisdn"
}

cr_version(){
	cr_version="BM_MF833V1.0.0B02_0329"
	cw_version="$(my_uci_get anyversion.device.device_version).$(my_uci_get anyversion.device.version_date)"
	if [ -z "$cr_version" ];then
		cr_version="BM_MF833V1.0.0B02_0329"
	fi
}

hw_version(){
	hw_version="V1.0"
	hw_version="$(my_uci_get anyversion.device.device_model)"
	if [ -z "$hw_version" ];then
		hw_version="V1.0"
	fi
}

LocalDomain(){
	LocalDomain="m.home"
}


WirelessMode(){
	WirelessMode="4"
	echo -n "$WirelessMode" #应该是标准的AP模式
}

CountryCode(){
	CountryCode="CN"
	echo -n "$CountryCode"
}

Channel(){
	Channel="0"
}

HT_MCS(){
	HT_MCS=""
}

wifi_band(){
	wifi_band="b"
}
wifi_11n_cap(){
	wifi_11n_cap="1"
}

MAX_Access_num(){
	MAX_Access_num="10"
	MAX_Access_num="$(my_uci_get wireless.default_radio0.maxassoc)"
	echo -n "$MAX_Access_num"
}

m_MAX_Access_num(){
	m_MAX_Access_num="0"
}

MAX_Station_num(){
	MAX_Station_num="32"
	MAX_Station_num="$(my_uci_get wireless.default_radio0.maxassoc)"
	if [ -z "$MAX_Station_num" ];then
		MAX_Station_num="32"
	fi
	echo -n "$MAX_Station_num"
}

#Group after login: wifi_sta_connection,pswan_priority,wifiwan_priority,ethwan_priority
###
wifi_sta_connection(){
	wifi_sta_connection="0"
	wifi_sta_connection=$(iw dev wlan0 station dump | grep Station | wc -l)
	if [ -z "$wifi_sta_connection" ];then
		wifi_sta_connection="0"
	fi
}

pswan_priority(){
	pswan_priority="1"
	echo -n "$pswan_priority"
}
wifiwan_priority(){
	wifiwan_priority="2"
	echo -n "$wifiwan_priority"
}
ethwan_priority(){
	ethwan_priority="3"
	echo -n "$ethwan_priority"
}
####


wifi_wps_index(){
	wifi_wps_index="1"
	echo -n "$wifi_wps_index"
}

WscModeOption(){
	WscModeOption="0"
}

wps_mode(){
	wps_mode=""
}

WPS_SSID(){
	WPS_SSID=""
}

show_qrcode_flag(){
	show_qrcode_flag="0"
}
m_show_qrcode_flag(){
	m_show_qrcode_flag="0"
}

Key1Str1(){
	Key1Str1="12345"
}
m_Key1Str1(){
	m_Key1Str1="12345"
}

Key2Str1(){
	Key2Str1=""
}
m_Key2Str1(){
	m_Key2Str1=""
}

Key3Str1(){
	Key3Str1=""
}
m_Key3Str1(){
	m_Key3Str1=""
}

Key4Str1(){
	Key4Str1=""
}
m_Key4Str1(){
	m_Key4Str1=""
}

DefaultKeyID(){
	DefaultKeyID="0"
}
m_DefaultKeyID(){
	m_DefaultKeyID="0"
}

rotationFlag(){
	rotationFlag=""
}

update_type(){
	update_type="mifi_ota"
	update_type=""
}

#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=sdcard_mode_option,sd_card_state,HTTP_SHARE_STATUS,HTTP_SHARE_WR_AUTH,HTTP_SHARE_FILE&multi_data=1&_=1555077065358
#{"sdcard_mode_option":"0","sd_card_state":"0","HTTP_SHARE_STATUS":"","HTTP_SHARE_WR_AUTH":"readWrite","HTTP_SHARE_FILE":""}
sdcard_mode_option(){
	sdcard_mode_option="0"
}

sd_card_state(){
	sd_card_state="0"
}

HTTP_SHARE_STATUS(){
	HTTP_SHARE_STATUS=""
}

HTTP_SHARE_WR_AUTH(){
	HTTP_SHARE_WR_AUTH="readWrite"
}

HTTP_SHARE_FILE(){
	HTTP_SHARE_FILE=""
}


#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=lan_station_list&_=1555076372714
#{"lan_station_list":[]}
#{"lan_station_list":[{"hostname":"DESKTOP-3ID68S9","mac_addr":"00:A0:C6:00:00:00"}]}
lan_station_list(){
	lan_station_list="[]"
	lan_station_list='[{"hostname":"DESKTOP-3ID68S9","mac_addr":"00:A0:C6:00:00:00"}]'
}


#net_select
#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=current_network_mode,m_netselect_save,net_select_mode,m_netselect_contents,net_select,ppp_status,modem_main_state&multi_data=1&_=1555077855567
#{"current_network_mode":"","m_netselect_save":"","net_select_mode":"","m_netselect_contents":"","net_select":"NETWORK_auto","ppp_status":"ppp_disconnected","modem_main_state":"modem_init_complete"}
current_network_mode(){
	current_network_mode=""
}

m_netselect_save(){
	m_netselect_save=""
}

net_select_mode(){
	net_select_mode=""
}

m_netselect_contents(){
	m_netselect_contents=""
}

net_select(){
	net_select="NETWORK_auto"
}


#apn_setting
#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=APN_config0,APN_config1,APN_config2,APN_config3,APN_config4,APN_config5,APN_config6,APN_config7,APN_config8,APN_config9,APN_config10,APN_config11,APN_config12,APN_config13,APN_config14,APN_config15,APN_config16,APN_config17,APN_config18,APN_config19,ipv6_APN_config0,ipv6_APN_config1,ipv6_APN_config2,ipv6_APN_config3,ipv6_APN_config4,ipv6_APN_config5,ipv6_APN_config6,ipv6_APN_config7,ipv6_APN_config8,ipv6_APN_config9,ipv6_APN_config10,ipv6_APN_config11,ipv6_APN_config12,ipv6_APN_config13,ipv6_APN_config14,ipv6_APN_config15,ipv6_APN_config16,ipv6_APN_config17,ipv6_APN_config18,ipv6_APN_config19,m_profile_name,profile_name,wan_dial,pdp_type,pdp_select,index,Current_index,apn_auto_config,ipv6_apn_auto_config,apn_mode,wan_apn,ppp_auth_mode,ppp_username,ppp_passwd,ipv6_wan_apn,ipv6_pdp_type,ipv6_ppp_auth_mode,ipv6_ppp_username,ipv6_ppp_passwd,apn_num_preset&multi_data=1&_=1555077946968
#{"APN_config0":"Default($)Default($)manual($)($)($)($)($)IP($)auto($)($)auto($)($)","APN_config1":"","APN_config2":"","APN_config3":"","APN_config4":"","APN_config5":"","APN_config6":"","APN_config7":"","APN_config8":"","APN_config9":"","APN_config10":"","APN_config11":"","APN_config12":"","APN_config13":"","APN_config14":"","APN_config15":"","APN_config16":"","APN_config17":"","APN_config18":"","APN_config19":"","ipv6_APN_config0":"","ipv6_APN_config1":"","ipv6_APN_config2":"","ipv6_APN_config3":"","ipv6_APN_config4":"","ipv6_APN_config5":"","ipv6_APN_config6":"","ipv6_APN_config7":"","ipv6_APN_config8":"","ipv6_APN_config9":"","ipv6_APN_config10":"","ipv6_APN_config11":"","ipv6_APN_config12":"","ipv6_APN_config13":"","ipv6_APN_config14":"","ipv6_APN_config15":"","ipv6_APN_config16":"","ipv6_APN_config17":"","ipv6_APN_config18":"","ipv6_APN_config19":"","m_profile_name":"China Telecom 4G","profile_name":"","wan_dial":"","pdp_type":"IP","pdp_select":"","index":"","Current_index":"","apn_auto_config":"China Telecom 4G($)ctlte($)auto($)*99#($)none($)($)($)IP($)auto($)($)auto($)($)","ipv6_apn_auto_config":"","apn_mode":"auto","wan_apn":"ctlte","ppp_auth_mode":"none","ppp_username":"","ppp_passwd":"","ipv6_wan_apn":"","ipv6_pdp_type":"","ipv6_ppp_auth_mode":"none","ipv6_ppp_username":"","ipv6_ppp_passwd":"","apn_num_preset":""}

APN_config0(){
	APN_config0="Default($)Default($)manual($)($)($)($)($)IP($)auto($)($)auto($)($)"
}

m_profile_name(){
	m_profile_name="China Telecom 4G"
}

profile_name(){
	profile_name=""
}

wan_dial(){
	wan_dial=""
}

index(){
	index=""
}

Current_index(){
	Current_index=""
}

apn_auto_config(){
	apn_auto_config="China Telecom 4G($)ctlte($)auto($)*99#($)none($)($)($)IP($)auto($)($)auto($)($)"
}

ipv6_apn_auto_config(){
	ipv6_apn_auto_config=""
}

apn_mode(){
	apn_mode="auto"
}

wan_apn(){
	wan_apn="ctlte"
}
ipv6_wan_apn(){
	ipv6_wan_apn=""
}

ppp_auth_mode(){
	ppp_auth_mode="none"
}
ipv6_ppp_auth_mode(){
	ipv6_ppp_auth_mode="none"
}

ppp_username(){
	ppp_username=""
}
ipv6_ppp_username(){
	ipv6_ppp_username=""
}

ppp_passwd(){
	ppp_passwd=""
}
ipv6_ppp_passwd(){
	ipv6_ppp_passwd=""
}

apn_num_preset(){
	apn_num_preset=""
}

#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=user_ip_addr&_=1555078079026
#{"user_ip_addr":"192.168.0.101"}

user_ip_addr(){
	user_ip_addr="192.168.0.101"
}

#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=station_list&_=1555078079052
#{"station_list":[{"connect_time":783,"ssid_index":"1","dev_type":"wifi","mac_addr":"AC:E0:10:11:4A:BB","hostname":"WinTop00","ip_addr":"192.168.0.100","ip_type":"DHCP"},{"connect_time":732,"ssid_index":"1","dev_type":"wifi","mac_addr":"70:1C:E7:43:EF:13","hostname":"DESKTOP-3ID68S9","ip_addr":"192.168.0.101","ip_type":"DHCP"}]}


#ap_station
##http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&multi_data=1&cmd=wifi_profile_num,wifi_profile,wifi_profile1,wifi_profile2,wifi_profile3,wifi_profile4,wifi_profile5,wifi_profile6,wifi_profile7,wifi_profile8,wifi_profile9&_=1555078563352
###{"wifi_profile_num":"0","wifi_profile":"","wifi_profile1":"","wifi_profile2":"","wifi_profile3":"","wifi_profile4":"","wifi_profile5":"","wifi_profile6":"","wifi_profile7":"","wifi_profile8":"","wifi_profile9":""}

##h.1/goform/goform_get_cmd_process?isTest=false&multi_data=1&cmd=scan_finish,EX_APLIST,EX_APLIST1&_=1555078939777
###{"scan_finish":"1","EX_APLIST":"0,0,@Inner,4,11,WPAPSKWPA2PSK,CCMP,c8:ee:a6:04:d5:8b;0,0,@Inner,4,11,WPAPSKWPA2PSK,CCMP,44:94:fc:85:22:ef;0,0,MIFI_CC6F,4,1,WPA2PSK,CCMP,c8:ee:a6:bb:cc:70;0,0,@Inner_CU,4,2,WPAPSKWPA2PSK,TKIPCCMP,78:58:60:53:b1:6c;0,0,MERCURY_AC9C,4,6,WPAPSKWPA2PSK,CCMP,6c:59:40:5a:ac:9c;0,0,6-1-1102,3,1,WPAPSKWPA2PSK,CCMP,24:69:68:ce:61:26;0,0,alink_QINYUAN_LIVING_WATERPURIFI,3,6,OPEN,NONE,b0:f8:93:13:eb:d4;0,0,HUAWEI-R3QALW,1,6,WPA2PSK,CCMP,f0:43:47:04:8d:c0;0,0,@PHICOMM_40,0,4,WPAPSKWPA2PSK,TKIPCCMP,cc:81:da:55:7f:48","EX_APLIST1":""}

wifi_profile_num(){
	wifi_profile_num="0"
}

wifi_profile(){
	wifi_profile=""
}

wifi_profile1(){
	wifi_profile1=""
}
wifi_profile2(){
	wifi_profile2=""
}
wifi_profile3(){
	wifi_profile3=""
}
wifi_profile4(){
	wifi_profile4=""
}
wifi_profile5(){
	wifi_profile5=""
}
wifi_profile6(){
	wifi_profile6=""
}
wifi_profile7(){
	wifi_profile7=""
}
wifi_profile8(){
	wifi_profile8=""
}
wifi_profile9(){
	wifi_profile9=""
}



#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&multi_data=1&cmd=scan_finish,EX_APLIST,EX_APLIST1&_=1555078939777
#{"scan_finish":"1","EX_APLIST":"0,0,@Inner,4,11,WPAPSKWPA2PSK,CCMP,c8:ee:a6:04:d5:8b;0,0,@Inner,4,11,WPAPSKWPA2PSK,CCMP,44:94:fc:85:22:ef;0,0,MIFI_CC6F,4,1,WPA2PSK,CCMP,c8:ee:a6:bb:cc:70;0,0,@Inner_CU,4,2,WPAPSKWPA2PSK,TKIPCCMP,78:58:60:53:b1:6c;0,0,MERCURY_AC9C,4,6,WPAPSKWPA2PSK,CCMP,6c:59:40:5a:ac:9c;0,0,6-1-1102,3,1,WPAPSKWPA2PSK,CCMP,24:69:68:ce:61:26;0,0,alink_QINYUAN_LIVING_WATERPURIFI,3,6,OPEN,NONE,b0:f8:93:13:eb:d4;0,0,HUAWEI-R3QALW,1,6,WPA2PSK,CCMP,f0:43:47:04:8d:c0;0,0,@PHICOMM_40,0,4,WPAPSKWPA2PSK,TKIPCCMP,cc:81:da:55:7f:48","EX_APLIST1":""}
scan_finish(){
	scan_finish="1"
}

EX_APLIST(){
	EX_APLIST="0,0,@Inner,4,11,WPAPSKWPA2PSK,CCMP,c8:ee:a6:24:d5:8b;0,0,@Inner,4,11,WPAPSKWPA2PSK,CCMP,44:94:fc:86:22:ef;0,0,MIFI_CC6F,4,1,WPA2PSK,CCMP,c8:ee:a6:bb:cc:70;0,0,@Inner_CU,4,2,WPAPSKWPA2PSK,TKIPCCMP,78:58:60:53:b1:6c;0,0,MERCURY_AC9C,4,6,WPAPSKWPA2PSK,CCMP,6c:59:40:5a:ac:9c;0,0,6-1-1102,3,1,WPAPSKWPA2PSK,CCMP,24:69:68:ce:61:26;0,0,alink_QINYUAN_LIVING_WATERPURIFI,3,6,OPEN,NONE,b0:f8:93:13:eb:d4;0,0,HUAWEI-R3QALW,1,6,WPA2PSK,CCMP,f0:43:47:04:8d:c0;0,0,@PHICOMM_40,0,4,WPAPSKWPA2PSK,TKIPCCMP,cc:81:da:55:7f:48"
}


EX_APLIST1(){
	EX_APLIST1=""
}

#wifi_advance
#mac_filter
#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&multi_data=1&cmd=ACL_mode,wifi_mac_black_list,wifi_hostname_black_list,wifi_cur_state,user_ip_addr,client_mac_address,wifi_mac_white_list&_=1555079131046
#{"ACL_mode":"2","wifi_mac_black_list":"","wifi_hostname_black_list":"","wifi_cur_state":"1","user_ip_addr":"192.168.0.101","client_mac_address":"70:1C:E7:43:EF:13","wifi_mac_white_list":""}
ACL_mode(){
	ACL_mode="2"
}

wifi_mac_black_list(){
	wifi_mac_black_list=""
}

wifi_hostname_black_list(){
	wifi_hostname_black_list=""
}

client_mac_address(){
	client_mac_address="70:1C:E7:43:EF:13"
}

wifi_mac_white_list(){
	#wifi_mac_wh#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=Sleep_interval&_=1555079602069
	:
}
	
	
#{"Sleep_interval":"10"}
Sleep_interval(){
	Sleep_interval="10"
}

#http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=openEnable,closeEnable,openTime,closeTime&multi_data=1&_=1555079602130
#{"openEnable":"0","closeEnable":"0","openTime":"","closeTime":""}

openEnable(){
	openEnable="0"
}

closeEnable(){
	closeEnable="0"
}

openTime(){
	openTime=""
}

closeTime(){
	closeTime=""
}

#router_setting
##http://192.168.0.1/goform/goform_get_cmd_process?isTest=false&cmd=lan_ipaddr,lan_netmask,mac_address,dhcpEnabled,dhcpStart,dhcpEnd,dhcpLease_hour&multi_data=1&_=1555079699319
###{"lan_ipaddr":"192.168.0.1","lan_netmask":"255.255.255.0","mac_address":"","dhcpEnabled":"1","dhcpStart":"192.168.0.100","dhcpEnd":"192.168.0.200","dhcpLease_hour":"24"}

lan_ipaddr(){
	lan_ipaddr="$(my_uci_get network.lan.ipaddr)"
    if [ -z "$lan_ipaddr" ];then                                                                                                   
		lan_ipaddr="192.168.0.1"
    fi
	echo -n "$lan_ipaddr"
}

#netmask only support 255.255.255.0 
lan_netmask(){
	lan_netmask="255.255.255.0"
	lan_netmask="$(my_uci_get network.lan.netmask)"
        if [ -z "$lan_netmask" ];then                                                                                                   
			lan_netmask="255.255.255.0"
        fi
		echo -n $lan_netmask
}

dhcpEnabled(){
	dhcpEnabled="$(my_uci_get dhcp.lan.ignore)"
    if [ "$dhcpEnabled" == "1" ];then                                                                                                   
		dhcpEnabled="0"
	else
		dhcpEnabled="1"
    fi 
	echo -n "$dhcpEnabled"
}

dhcpStart(){
	lanip="$(uci get network.lan.ipaddr)"
	lanip_last="$(echo "$lanip" | awk -F. '{print $4}')"
	lanip_last_plus1="$((lanip_last+1))"
	lanip_prefix="$(echo "$lanip" | awk -F. '{print $1"."$2"."$3"."}')"
	
	dhcpStart="$(my_uci_get dhcp.lan.start)"
	
	if [ -z "$dhcpStart" ];then
		dhcpStart="${lanip_prefix}${lanip_last_plus1}"
	else
		dhcpStart="${lanip_prefix}${dhcpStart}"
	fi
	echo -n "$dhcpStart"
}

dhcpEnd(){
	lanip="$(uci get network.lan.ipaddr)"
	lanip_prefix="$(echo "$lanip" | awk -F. '{print $1"."$2"."$3"."}')" #192.168.8.
	
	dhcpStart="$(dhcpStart)"
	limit="$(my_uci_get dhcp.lan.limit)"
	
	if [ -z "$limit" ] || [ "$limit" == "0" ];then
		limit=20
	fi
	
	dhcpStartLast="$(echo $dhcpStart | awk -F. '{print $4}')"
	dhcpEndLast="$((dhcpStartLast+limit))"
	
	dhcpEnd="${lanip_prefix}${dhcpEndLast}"
	echo -n "$dhcpEnd"
}

dhcpLease_hour(){
	dhcpLease_hour="$(my_uci_get dhcp.lan.leasetime | tr -d 'h')"
	if [ -z "$dhcpLease_hour" ];then
		dhcpLease_hour="24"
	fi
	echo -n "$dhcpLease_hour"
}


status_all(){
	json_init
	json_add_string modem_main_state "$(modem_main_state)"
	json_add_string pin_status "$(pin_status)"
	json_add_string blc_wan_mode "$(blc_wanmode)"
	json_add_string blc_wan_auto_mode "$(blc_wan_auto_mode)"

	status="$(json_dump)"
}

}
