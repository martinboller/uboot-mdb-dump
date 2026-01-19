#!/usr/bin/perl

require "/lib/core.cgi";

my $sn = '';
## read sn 
foreach (qx|hexdump -C -s 0x88 -n 8 /dev/mtd2|) {
	$sn = $1 if (/^\S+\s+((\w\w ){8})/) ;
}
$sn =~ s/ //g;

open WT,'>','/proc/authmode' and print WT "$sn$sn" and close WT;
open WT,'>','/tmp/sn' and print WT $sn,"\n" and close WT;

my $authok = '';
open RD,'<','/proc/authmode' and ($authok = <RD>) and close RD;

## write auth status
system ("uci set my.main.authok=$authok");
system ("uci set my.main.authcode=$sn") if ($authok);

my $ver;
open RD,'<','/etc/openwrt_release';
while (<RD>) {
	$ver= $1 if (/^DISTRIB_REVISION='([^']+)/);
}
close RD;

system ("uci set my.main.fm_version=$ver");
system ("uci commit");

&run_as_daemon ("/etc/exec/yunlogin");

&run_as_daemon ("/etc/exec/sysinfo init");

&_log("$0 fin\n");
