#!/bin/sh

#本地log目录
path_mes="/etc/mes_test"
path_script="${path_mes}/script"
path_curl_log="${path_mes}/curl_log"
path_temp_log="${path_mes}/tmp_log"

###用于存放脚本的目录
if [ ! -d "${path_script}" ];then
    mkdir -p ${path_script}
fi

###用于存放curl的http调试日志
if [ ! -d "${path_curl_log}" ];then
    mkdir -p ${path_curl_log}
fi

###用于存放其他的记录的目录
if [ ! -d "${path_temp_log}" ];then
    mkdir -p ${path_temp_log}
fi

#服务器域名或者IP
test_server="10.0.0.82"
firmware="newOS"
model_wget=`uci get anyversion.device.device_model_displayname`
if [ -z "$model_wget" ];then
    model_wget="WE1626"
fi

###model_wget是获取的脚本的路径，而model才是真正的产品型号
var_check="$1"
var=`echo "$var_check" | grep "[A-Za-z]\{1,\}"`

if [ ! -z "$var_check" ] && [ ! -z "$var" ];then

    var=`echo "$var" | tr '[a-z]' '[A-Z]'`
    model="$var"
else
    model=`echo "$model_wget"`
fi

#系统相关参数
cpu=`cat /proc/cpuinfo |sed -n 1p|cut -d " " -f4`
ram=`cat /proc/meminfo | grep MemTotal|cut -d ":" -f2|sed 's/ //g'`
flashid=`cat /proc/flashid`
version=`uci get anyversion.device.device_version`
version_sys="$version"
mes_version="v4.5.0"
version="MES_CRT-${mes_version};${firmware}-${version}"

art_mac=`hexdump -C -s 0x04 /dev/mtd2 | sed -n "1p"|cut -c 11-28|sed 's/\ //g'`
art_5g_mac=`hexdump -C -s 0x8004 /dev/mtd2 | sed -n "1p" | cut -c 11-28|sed 's/\ //g'`
lan_mac=`hexdump -C -s 0x28 /dev/mtd2 | sed -n "1p" | cut -c 11-28|sed 's/\ //g'`
wan_mac=`hexdump -C -s 0x2e /dev/mtd2 | sed -n "1p" | cut -c 11-28|sed 's/\ //g'`

#老化看门狗参数
#详见old_douptime脚本
wdFlag=""
wdGpio=""

#吞吐量参数
port1="ra0"
port2=""
througvalue=""

#打包相关参数
sn=""
cmei=""

#测试项目检测，有传参的则不测
test_project="$@"

###备注的获取
comment=`echo "$test_project" | awk -F "$1" '{print $2}' | grep -o "备注_.*" | cut -d "_" -f2  | cut -d " " -f1`
###订单号的获取
order=`echo "$test_project" | awk -F "$1" '{print $2}' | grep -o "订单_.*" | cut -d "_" -f2  | cut -d " " -f1`
###版本号的获取
ver_check=`echo "$test_project" | awk -F "$1" '{print $2}' | grep -o "ver_.*" | cut -d "_" -f2  | cut -d " " -f1`
###固件型号的获取
model_check=`echo "$test_project" | awk -F "$1" '{print $2}' | grep -o "model_.*" | cut -d "_" -f2  | cut -d " " -f1`

path_model="http://$test_server/zbt_factory/model/$model_wget/$firmware"
path_test="http://$test_server/zbt_factory/mes_test"

###文件大小，只比较库和bin文件大小
curl_bytes=""
lib_bytes01=""
lib_bytes02=""
maccalc_bytes="12464"

cat >/tmp/pass.txt<<EOF
------------------------------------------------------------
     ########     ###     ######   ######
     ##     ##   ## ##   ##    ## ##    ##
     ##     ##  ##   ##  ##       ##
     ########  ##     ##  ######   ######
     ##        #########       ##       ##
     ##        ##     ## ##    ## ##    ##
     ##        ##     ##  ######   ######
------------------------------------------------------------
EOF
pass=`cat /tmp/pass.txt`


###显示SSID
network_show_ssid_fun()
{
    art_ssid=`uci get wireless.default_radio0.ssid 2> /dev/null`
    art_5g_ssid=""
    ###显示ssid
    echo " 2.4G无线的SSID为：${art_ssid}"
    if [ ! -z "$port2" ];then
	echo " 5.8G无线的SSID为：${art_5g_ssid}"
    fi
}

while true
do
    ###从服务器拉取maccalc脚本
    if [ ! -f "${path_script}/maccalc" ];then

        echo  " 正在下载maccalc工具..."  
        wget -T 5 -P ${path_script}/ $path_model/maccalc &> /dev/null
        maccalc_file_check=`ls -l ${path_script}/maccalc | awk -F " " '{print $5}'`
        if [ "$maccalc_file_check" != "$maccalc_bytes" ];then
	    rm ${path_script}/maccalc -rf
	    continue
	fi
	chmod 777 ${path_script}/maccalc
    else
        maccalc_file_check=`ls -l ${path_script}/maccalc | awk -F " " '{print $5}'`
        if [ "$maccalc_file_check" != "$maccalc_bytes" ];then
	    rm ${path_script}/maccalc -rf
	    continue
	fi
	break
    fi
done

#################### 配置一些东西 ################################
while true
do

rm -rf /tmp/test_pack
rm -rf /bin/throughput
rm -rf /tmp/testwrt
rm -rf ${path_curl_log}/test_process.log
rm -rf ${path_curl_log}/order_list.log
rm -rf ${path_curl_log}/device_model.log
test_pack_vcheck=`cat ${path_script}/test_pack 2> /dev/null | grep ^mes | cut -d "=" -f2 | sed 's/\"//g'`
douptime_vcheck=`cat ${path_script}/douptime 2> /dev/null | grep ^mes | cut -d "=" -f2 | sed 's/\"//g'`
throughput_vcheck=`cat ${path_script}/throughput 2> /dev/null | grep ^mes | cut -d "=" -f2 | sed 's/\"//g'`
testwrt_vcheck=`cat ${path_script}/testwrt 2> /dev/null | grep ^mes | cut -d "=" -f2 | sed 's/\"//g'`

if [ "$testwrt_vcheck" != "$mes_version" ];then
    rm -rf ${path_script}/testwrt
fi
:<<!
if [ "$test_pack_vcheck" != "$mes_version" ];then
    rm -rf ${path_script}/test_pack
fi
if [ "$douptime_vcheck" != "$mes_version" ];then
    rm -rf ${path_script}/douptime
fi
if [ "$throughput_vcheck" != "$mes_version" ];then
    rm -rf ${path_script}/throughput
fi
!

#查看测试进度
cutart_mac1=`echo "$art_mac" | cut -c 1-2`
cutart_mac2=`echo "$art_mac" | cut -c 3-4`
cutart_mac3=`echo "$art_mac" | cut -c 5-6`
cutart_mac4=`echo "$art_mac" | cut -c 7-8`
cutart_mac5=`echo "$art_mac" | cut -c 9-10`
cutart_mac6=`echo "$art_mac" | cut -c 11-12`

art_mac_add1="${cutart_mac1}:${cutart_mac2}:${cutart_mac3}:${cutart_mac4}:${cutart_mac5}:${cutart_mac6}"
art_mac_add2=`${path_script}/maccalc add $art_mac_add1 +2 | tr '[A-Z]' '[a-z]' | sed 's/\://g'`

########## 型号检测 ###############################################
###只有传入型号参数并且不相等的时候才会校验型号    
if [ "$model" != "$model_wget" ];then

    model=`echo "$model" | tr '[a-z]' '[A-Z]'`
    while true                                                                    
    do
	search_model=`curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/device_model.log -s "http://$test_server/api/device_model"`
        if [ "$search_model" = "" ];then
	    echo -e "\033[31m 数据查询失败，正在尝试重新连接...\033[0m"
	    continue
	fi  

        result_model=`echo "$search_model" | sed 's/\-/_/g'`
        op_model=`echo "$model" | sed 's/\-/_/g'`
        reson_model=`echo "$result_model" | grep -i -o -w "${op_model}\"" | sed 's/\"//g' | wc -l`
							        
        if [ "$reson_model" -lt "1" ] ;then

	    echo -e "\033[31m 服务器没有找到该产品型号，请联系管理员添加该型号 \033[0m"
	    echo -e "\033[31m $failed\033[0m"                                     
	    exit 0
	else
	    break
	fi  
    done
fi

########## 订单号校验 ###############################################
###只有传入订单号信息参数的时候才会校验订单
if [ "$order" != "" ];then
    while true                                                                    
    do
        search_order=`curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/order_list.log -s "http://$test_server/api/device/get_bill_list"`
	if [ "$search_order" = "" ];then
             echo -e "\033[31m 订单列表获取失败，正在尝试重新连接...\033[0m"
             continue
        fi

        order_code_result=`echo "$search_order" | grep "\"${order}\"" | wc -l`
        if [ "$order_code_result" -lt "1" ] ;then
	    echo -e "\e[31m 服务器没有找到该订单号，请联系管理员添加订单号 \e[0m"
	    echo " 传入的订单号: $order"
	    echo -e "\e[31m $failed\e[0m" 
	    exit 0
	else
	    echo -e "\e[32m 服务器有该订单号，请继续.. \e[0m"
	    break
	fi
    done
fi

###开始测试
if [ ! -z "$flashid" ];then
    echo " 当前FLASH ID为：$flashid"
    while true
    do
	auth=`cat /proc/authmode`
        if [ "$auth" = "0" ];then
	    echo " 当前设备未授权"
	    echo " 正在授权，请稍后..."
	    sleep 1
	else
	    echo " 当前设备已经授权"
	    break
	fi  
    done
fi

echo ""
echo " 开始进行产品测试"
echo " 当前生产型号：$model "
echo " CPU型号：$cpu "
echo " 当前内存：$ram "
echo " 当前固件和版本：$version "
###固件类型（固件型号）校验
if [ ! -z "$model_check" ];then
    if [ "$model_check" != "$model_wget" ];then
	echo -e "\033[31m 固件型号与参数不匹配 \033[0m"
	exit
    fi
fi
###固件版本校验
if [ ! -z "$ver_check" ];then
    if [ "$ver_check" != "$version_sys" ];then
	echo -e "\033[31m 固件版本与参数不匹配 \033[0m"
	exit
    fi
fi
echo " 当前2.4G MAC：$art_mac "
if [ ! -z "$port2" ];then

    echo " 5.8G MAC: $art_5g_mac"
fi
echo " 当前LAN MAC：$lan_mac "
echo " 当前WAN MAC：$wan_mac "
echo " "
if [ ! -z "$comment" ];then
    echo " 备注: $comment"
fi
if [ ! -z "$order" ];then
    echo " 订单号: $order"
fi

#查看测试进度
while true
do
    op_result=$(curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/test_process.log -s "http://$test_server/api/device_test_process?model=$model&mac=$art_mac_add2")
    if [ "$op_result" = "" ];then
	echo -e "\033[31m 数据查询失败，正在尝试重新连接...\033[0m"
	continue
    else
	break
    fi
done

###测试进度过滤
weight=`echo "$op_result" | grep "weight" | wc -l`
dobox=`echo "$op_result" | grep "pack" | wc -l`
wifi_test=`echo "$op_result" | grep "flow" | wc -l`
uptime=`echo "$op_result" | grep "aging" | wc -l`
common=`echo "$op_result" | grep "common" | wc -l`

###添加备注
if [ ! -z "$comment" ] && [ "$common" = "1" ] ;then
    while true
    do
        op_comment=`curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/comment.log -s "http://$test_server/api/device/comment_edit?mac=${art_mac_add2}&model=$model&comment=${comment}"`
	op_comment_restult=`echo "$op_comment" | grep "success" | wc -l`
	if [ "$op_comment_restult" -ge "1" ];then
            echo -e "\033[32m 添加备注成功，备注内容：${comment}\033[0m"
            break
        else
	    echo -e "\033[31m 添加备注失败,尝试重新上传..\033[0m"
	    continue
	fi
    done
fi

###绑定订单号
if [ ! -z "$order" ] && [ "$common" = "1" ] ;then
    while true
    do
        op_order=`curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/order.log -s "http://$test_server/api/device/assoc/order?mac=${art_mac_add2}&model=$model&order_sn=$order"`
	op_order_restult=`echo "$op_order" | grep "\"success\"" | wc -l`
        if [ "$op_order_restult" -ge "1" ];then
            echo -e "\033[32m 添加订单号成功，订单号：${order}\033[0m"
            break
        else
	    echo -e "\033[31m 添加订单号失败,尝试重新上传..\033[0m"
	    continue
	fi
    done
fi

###判断测试流程
if [ "$weight" = "1" ] ;then
    echo -e "\033[32m 已完成 称重 及前面所有项 \033[0m" 
    exit 0
elif [ "$dobox" = "1" ] ;then
    echo -e "\033[32m 已完成 打包，请进行称重 \033[0m" 
    exit 0

###标贴校对测试
elif [ "$wifi_test" = "1" ] && [ "$uptime" = "1" ];then

    echo -e "\033[32m 已完成 老化和吞吐量 测试，正在进行 标贴校对... \033[0m"
    ###服务器下载标贴校对文件
    while true
    do
	if [ ! -f "${path_script}/test_pack" ];then

	    echo " 正在下载校对标贴测试文件..."
	    wget -T 5 -P ${path_script}/ $path_test/test_pack &> /dev/null
	    chmod 777 ${path_script}/test_pack
	else
	    echo " 下载标贴校对测试文件成功"
	    chmod 777 ${path_script}/test_pack
	    break
	fi
    done

    chmod 777 ${path_script}/test_pack
    ${path_script}/test_pack "$lan_mac" "$sn" "$cmei"

    if [ -f "/tmp/pack_pass" ];then
	#上传打包情况
	while true
	do
	    op_result=$(curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/test_pack.log -s "http://$test_server/api/data_report?op=mac_verify&mac=$lan_mac&model=$model&result=pass")
	    upload=`echo "$op_result" | grep -o "pass"`
	    if [ "$upload" = "pass" ];then

		echo -e "\033[32m 标贴校对通过 \033[0m"   
		echo -e "\033[32m 标贴校对数据上传成功 \033[0m"
		echo -e "\033[32m $pass\033[0m"
		break
	    else
		echo -e "\033[31m 标贴校对数据上传失败,尝试重新上传..\033[0m"
	    fi
	done
	#重启文件系统
	echo ""
	echo " 系统即将复位关机..."
	jffs2reset -y
	reboot
	exit 0
    else
	echo -e "\033[32m 打包测试失败，强制退出测试，请重新运行CRT \033[0m"   
	exit
    fi

###老化和吞吐量测试
elif [ "$common" = "1" ] ;then

    echo -e "\033[32m 已完成 自检，正在进行 老化和吞吐量 测试... \033[0m" 

    ###老化数据获取
    if [ ! -f "/etc/douptime.log" ];then

	echo -e "\033[31m 此设备没有运行过老化程序，请重新进行老化 \033[0m"   
	###下载老化脚本
        while true
        do
            if [ ! -f "${path_script}/douptime" ];then

		echo " 正在下载老化测试文件..."
	        wget -T 5 -P ${path_script}/ $path_test/douptime &> /dev/null
	        chmod 777 ${path_script}/douptime
	    else
	        echo " 下载老化测试文件成功"            
	        chmod 777 ${path_script}/douptime
	        break
	    fi
	done

	echo "${path_script}/douptime $wdFlag $wdGpio  &" >> /etc/diag.sh
	chmod 777 ${path_script}/douptime
	${path_script}/douptime "$wdFlag" "$wdGpio"  &
	exit 
    fi

    ###提示用户的老化时间
    uptimepass=`cat /etc/douptime.log`
    hour=`expr $uptimepass / 3600`
    min=`expr $uptimepass % 3600 / 60`
    sec=`expr $uptimepass % 3600 % 60`

    echo -e "\033[42;37m 系统已经老化 ${hour}小时${min}分${sec}秒 \033[0m"   

    ###吞吐量测试
    ###下载吞吐量脚本
    while true
    do
	if [ ! -f "${path_script}/throughput" ];then

	    echo " 正在下载吞吐量测试文件..."
	    wget -T 5 -P ${path_script}/ $path_test/throughput &> /dev/null
	    chmod 777 ${path_script}/throughput
	else
	    echo " 下载吞吐量测试文件成功"
	    chmod 777 ${path_script}/throughput
	    break
	fi
    done

    chmod 777 ${path_script}/throughput 
    network_show_ssid_fun 
    ${path_script}/throughput "$port1" "$port2" "$througvalue"

    ###要上报的吞吐量数据
    throughput_data=`cat /tmp/throughput_data 2>/dev/null`
    throughput_data_5g=`cat /tmp/throughput_data_5g 2>/dev/null`
    throughput_data_6=`cat /tmp/throughput_data_6 2>/dev/null`
	
    ###要上报的老化数据
    uptimepass=`cat /etc/douptime.log`
    ###老化未满50分钟算没进行老化
    if [ "$uptimepass" -lt "3000" ];then
	uptimepass="0"
    fi

    ###上传老化和吞吐量数据
    while true
    do
	op_result=$(curl --connect-timeout 2 -m 2 --trace-ascii ${path_curl_log}/test_douptime.log -s "http://$test_server/api/data_report?op=aging_flow&mac=$lan_mac&model=$model&uptime=pass&runtime=$uptimepass&result=pass&band_2=$throughput_data&band_5=$throughput_data_5g&band_6=$throughput_data_6")
	upload=`echo "$op_result" | grep -o "pass"`
	if [ "$upload" = "pass" ];then

	    echo -e "\033[32m 老化和吞吐量和老化测试通过 \033[0m"   
	    echo -e "\033[32m 数据上传成功 \033[0m"   
	    echo -e "\033[32m $pass\033[0m"
	    break
	else
	    echo -e "\033[31m 老化和吞吐量数据上传失败,尝试重新上传..\033[0m"
	    continue
	fi
    done
    exit 0

###自检测试
else
    ###下载自检脚本
    while true
    do
	if [ ! -f "${path_script}/testwrt" ];then
	    echo " 正在下载自检测试文件..."
	    wget -T 5 -P ${path_script}/ $path_model/testwrt &> /dev/null
	    chmod 777 ${path_script}/testwrt
	else
	    echo " 下载自检测试文件成功"
	    chmod 777 ${path_script}/testwrt
	    break
	fi
    done

    chmod 777 ${path_script}/testwrt
    ${path_script}/testwrt $test_project
    exit 0
fi
done


