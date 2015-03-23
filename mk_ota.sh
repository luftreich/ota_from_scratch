#!/bin/bash - 
#===============================================================================
#
#          FILE: mk_ota.sh
# 
#         USAGE: ./mk_ota.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Tony lEE <lüftreich@gmail.com>
#  ORGANIZATION: 
#       CREATED: 03/20/2015 10:38
#      REVISION:  ---
#===============================================================================
#
#                     (c) Copyright LUFT.Ltd 2014 - 2144, All Rights Reserved
#
# Revision History:
#                       Modification     Tracking
# Author (core ID)          Date          Number     Description of Changes
# -------------------   ------------    ----------   ----------------------
#
# Lüftreich             **/**/2014        2.0        ****
# Lüftreich             **/**/2014        1.0        ****
#===============================================================================

# set -x              # Print commands and their arguments as they are executed
set -o nounset                              # Treat unset variables as an error

cur_cmd=`readlink -f $0`
cur_dir=${cur_cmd%/*}

cd $cur_dir || exit

orig_pkg=$cur_dir/orig_ota.zip
sign_pkg=sign_ota_`date +%Y_%m_%d`.zip

src_dir=$cur_dir/src
ota_dir=$cur_dir/otaupdate

ota_ip='192.168.1.20:8080'
old_firmware=00442023
lastest_fimware=00442024
# lastest_fimware=$old_firmware
# let lastest_fimware+=1

board=m201
ver_android='4.4.2'
str_fingerprint='MBX/m201/m201:4.4.2/KOT49H/20150318.V0823:user/test-keys'

param_file=$ota_dir/parameter.conf
debug_file=$ota_dir/debug.conf
update_file=$ota_dir/update.conf
form_file=$ota_dir/form.jsp
form_page="http://$ota_ip/otaupdate/form.jsp"
xml_file=$ota_dir/xml/update/ota_box_${old_firmware}.xml

mkdir -p $ota_dir/xml/{debug,update}
mkdir -p $ota_dir/xml/download/{zip,script}
sign_pkg=$ota_dir/xml/download/zip/$sign_pkg

cd $src_dir || exit
mkdir -p META-INF/com/google/android 
mkdir -p system/app
mkdir -p data/app
touch logo.img

apk_info=/tmp/.ota_apk_info
del_info=/tmp/.ota_apk_del
perm_info=/tmp/.ota_apk_perm
> $apk_info
for _apk in system/app/*.apk; do
    cat >> $apk_info << _EOS
delete("/$_apk"); set_perm(0,0,0644,"/$_apk");
_EOS
done
for _apk in data/app/*.apk; do
    cat >> $apk_info << _EOD
delete("/$_apk"); set_perm(1000,1000,0644,"/$_apk");
_EOD
done
cat $apk_info | awk '{print $1}' > $del_info
cat $apk_info | awk '{print $2}' > $perm_info

update_script='META-INF/com/google/android/updater-script'

cat > $update_script  << _EOF

ui_print("Created by Luftreich@imaxpo.com");

getprop("ro.product.device") == "$board" || abort("This package is for \"$board\" devices; this is a \"" + getprop("ro.product.device") + "\".");

ui_print("Mounting /system...");
mount("ext4", "EMMC", "/dev/block/system", "/system");

ui_print("Mounting /data...");
mount("ext4", "EMMC", "/dev/block/data", "/data");

ui_print("- Removing old files");
_EOF

cat $del_info >> $update_script

cat >> $update_script  << _EOF

ui_print("Extracting system and data...");
package_extract_dir("system", "/system");
package_extract_dir("data", "/data");

ui_print("Fixing permissions...");
_EOF

cat $perm_info >> $update_script

cat >> $update_script  << _EOF

ui_print("Unmounting /system /data...");
unmount("/system");
unmount("/data");

ui_print("Writing LOGO...");
write_raw_image(package_extract_file("logo.img"), "logo");

ui_print("Done.");

_EOF

sync
rm $orig_pkg $sign_pkg -f; sync
zip -r9 $orig_pkg *

cd - || exit
sign_apk='out/host/linux-x86/framework/signapk.jar'
key_a='build/target/product/security/testkey.x509.pem'
key_b='build/target/product/security/testkey.pk8'

#default_system_dev_certificate = (str) build/target/product/security/testkey
# openssl pkcs8 -in build/target/product/security/testkey.pk8 -inform DER -nocrypt

# java -Xmx2048m -jar out/host/linux-x86/framework/signapk.jar -w build/target/product/security/testkey.x509.pem build/target/product/security/testkey.pk8 /tmp/tmpYyg8fx out/target/product/m201/m201-ota-20150318.V0823.zip

unset _JAVA_OPTIONS
java -Xmx2048m -jar $sign_apk  -w $key_a  $key_b $orig_pkg $sign_pkg || exit
ls $sign_pkg >/dev/null || exit


    cat > $param_file << _EOF
android=$ver_android
device=$board
board=$board
_EOF

    cat > $form_file << _EOF
<%@ page language="java" import="java.util.*" pageEncoding="utf-8"%>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";
%>
<!DOCTYPE HTML>
<html lang="en-US">
<head>
	<base href="<%=basePath%>">
	<title></title>
</head>
<body>
	<form action="update" method="POST">
		id:<input name="id" type="text" value="1000"/><br>
		updating_apk_version:<input name="updating_apk_version" type="text" value="1.0"/><br>
		brand:<input name="brand" type="text" value="MBX"/><br>
		device:<input name="device" type="text" value="$board"/><br>
		board:<input name="board" type="text" value="$board"/><br>
		mac:<input name="mac" type="text" value="172.17.72.254"/><br>
		firmware:<input name="firmware" type="text" value="$old_firmware"/><br>
		android:<input name="android" type="text" value="$ver_android"/><br>
		time:<input name="time" type="text" value="`date +%c`"/><br>
		builder:<input name="builder" type="text" value="LT"/><br>
		fingerprint:<input name="fingerprint" type="text" value="$str_fingerprint"/><br>
		debug_conf:<input name="debug_conf" type="text" value="${form_page%/*}/debug.conf"/><br>
		update_conf:<input name="update_conf" type="text" value="${form_page%/*}/update.conf"/><br>
		<input type="submit" value="提交Submit" />
	</form>
</body>
</html>
_EOF
    
    [ -f $update_file ] || echo 'lastest=00000' > $update_file
    grep -q "^${old_firmware}" $update_file && sed -i "/^${old_firmware}/d" $update_file
    sed -i "s/^lastest.*/lastest=$lastest_fimware/g" $update_file
    cat >> $update_file << _EOF
$old_firmware=http://$ota_ip/otaupdate/xml/update/${xml_file##*/}
_EOF

    ota_file=${sign_pkg##*/}
    md5_sum=`md5sum $sign_pkg | awk '{print $1}'`
    file_size=`\stat $sign_pkg | grep Size | awk '{print $2}'`
    # locattr_dir=/storage/external_storage/sdcard1
    locattr_dir=/storage/external_storage/sda1 ## Udisk

    cat > $xml_file << _EOF
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<updata>
   <command force="false" name="update_with_inc_ota">
      <url name="update.zip" locattr="$locattr_dir/update.zip" updatezip="true">http://$ota_ip/otaupdate/xml/download/zip/$ota_file</url>
      <md5 name="update.zip">$md5_sum</md5>
      <storagemem>$file_size</storagemem>
      <!--语言从上往下选择，如何没有相对应的语言，就选择英文。country的值是按照android标准获取的国家代码-->
      <description country="CN" language="zh">1.修正鼠标有时无法使用的bug.2.优化视频播放效果</description>
      <description country="TW" language="zh">1.修正鼠標有時無法使用的bug.2.優化視頻播放效果.</description>
      <description country="ELSE" language="en">1.fix a bug that the mouse can't be used sometimes.2.perfect the video play effect.</description>
      <!--当前差分包的fingerprint：
$str_fingerprint
当差分包对应升级版本的fingerprint:
$str_fingerprint
-->
   </command>
</updata>
_EOF


unix2dos $param_file
unix2dos $debug_file
unix2dos $update_file
unix2dos $form_file
unix2dos $xml_file

\cp -f $update_file $debug_file
chmod -R 755 $ota_dir
sync
tree $ota_dir
# cat $xml_file
echo "All is OK ! <DEMO> $form_page"
echo "Sign OTA PKG: ${sign_pkg##*scratch/}"

exit $?

