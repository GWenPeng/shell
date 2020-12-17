#!/usr/bin/bash

#下载ftp大包并替换之
echo  "Please enter  packageName:"
# shellcheck disable=SC2162
read  packageName
curl -O "$packageName"
sleep 3
echo "${packageName##*/}"
ReplacePackage/as_7.0/replace_package.sh  /root/"${packageName##*/}"
sleep 3


kubesuite reset 127.0.0.1
# shellcheck disable=SC2046
# shellcheck disable=SC2006
docker rmi -f `docker images -q`
 
rm -rf active
#判断expect不存存在则安装之
if [ ! -f " /usr/bin/expect" ]; then
    yum -y install expect
fi
#往active写入激活文本

cat<<EOF >> /root/active
#!/usr/bin/expect -f

spawn deploy_tools.py
expect "1. Activate Cluster"
send "1"
send "\n"
expect "this operation will clear all the data"
send "Y"
send "\n"
expect "zh_CN"
send "zh_CN"
send "\n"
expect "1: Standard"
send "1"
send "\n"
expect "1: Erds Service"
send "1"
send "\n"
expect "IP List:"
send "1"
send "\n"
expect "Master Node IP"
send "Y"
send "\n"
expect "Activate Cluster: Succeed"
interact
EOF

chmod +x ./active
./active

