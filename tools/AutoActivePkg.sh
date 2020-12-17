#!/usr/bin/bash

echo  "Please enter  packageName:"
read  packageName
curl -O $packageName
sleep 3
echo "${packageName##*/}"
ReplacePackage/as_7.0/replace_package.sh  /root/${packageName##*/}
sleep 3


kubesuite reset 127.0.0.1
docker rmi -f `docker images -q`
 
rm -rf active
if [ ! -f " /usr/bin/expect" ]; then
    yum -y install expect
fi

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

