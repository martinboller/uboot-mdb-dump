#!/bin/sh
echo "Content-Type:text/html;charset=utf-8"
echo ""

model=`cat /proc/cpuinfo |sed -n 2p|cut -d ":" -f2|sed 's/ //g'`
flashid=`cat /proc/flashid`
snserver="https://www.ac-link.com"
authmode=`cat /proc/authmode`

if [ "$authmode" != "1" ];then
	mac_old=`hexdump -C -s 0x2e /dev/mtd2|sed -n "1p"|cut -c 11-28|sed 's/\ //g'`
	sn=`curl -k "$snserver/api/get_mqwrt_sn?flashid=$flashid&model=$model&mac=$mac_old&token=1234567" |cut -c  14-29`

	#echo "$sn"
	#写入sn

	#校验sn
	#计算SN长度判断是否合法
	snl=`echo "$sn"|wc -L`

	if [ "$snl" = "16" ];then
		cp /dev/mtd2 /tmp/art
		sleep 1
		write_sn=`sn_set $sn`
		#刷入改过SN的art文件
		cat /tmp/art > /dev/mtdblock2    
	else 
		echo "SN error,Please refresh"
	fi

	#######################校验SN########################################################
	newsn=`hexdump -C -s 0x88 /dev/mtd2 |sed -n "1p"|cut -c 11-33|sed 's/\ //g'`
	echo -n $newsn$newsn >/proc/authmode
	authmode=`cat /proc/authmode`

	if [ "$authmode" = "1" ] ;then
		echo "Auth success" 
	else 
		echo "Auth fail,Please refresh"
	fi
else
    echo "This device is authorized"
fi




















