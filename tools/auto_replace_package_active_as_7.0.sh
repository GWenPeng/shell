#!/usr/bin/env bash

function replace_package() {
    echo "---------------------------------- START ----------------------------------"

    if [ "$1" = "" ]; then
        echo "Please give the package download url"
        exit 1
    fi

    packname=${1##*/}
    path=$(pwd)
    workpath=/sysvol/apphome
    pillar_config=/srv/pillar/salt.sls

    echo "Downloading Package..."
    curl -o $workpath/$packname $1

    echo "Checking Package..."
    cd $workpath
    if [ ! -f "$packname" ]; then
        echo 'Please download package first.'
        exit 1
    fi

    echo "---------------------------------------------------------------------------"

    echo "Replace Package Start..."
    echo "stop services"
    systemctl stop ecms_troubleshoot_service
    systemctl stop eisooapp

    echo "kill processes still on $workpath"
    ls -l /proc/*/fd/* 2>/dev/null | grep $workpath
    ls -l /proc/*/fd/* 2>/dev/null | grep $workpath | awk '{print $9}' | awk -F "/" '{print $3}' | uniq | while read pid; do kill $pid; done

    echo "Clear $workpath"
    rm -rf $(ls $workpath | grep -v "$packname")

    echo "unzip package"
    tar -zxf $packname

    cp -r /sysvol/apphome/service_script/* /usr/lib/systemd/system/
    systemctl daemon-reload

    echo "syspatch"
    python /sysvol/apphome/app/ecmstools/syspatch/syspatch.py

    echo "restart services"
    systemctl restart eisooapp
    sleep 10

    if [ -f "/usr/lib/sysctl.d/proton-cs.conf" ]; then
        echo "---- sysctl -p /usr/lib/sysctl.d/proton-cs.conf ----"
        sysctl -p /usr/lib/sysctl.d/proton-cs.conf
    fi

    cd $workpath
    rm -rf $packname

    set +x
    echo "Replace Package Finish"

    echo "---------------------------------------------------------------------------"
}

function active() {
    echo "Prepare For Active..."
    kubesuite reset 127.0.0.1
    docker rmi -f $(docker images -q)

    if [ ! $(command -v expect) ]; then
        echo "install expect..."
        yum -y install expect
    fi

    echo "create /root/auto_active_cluster..."
    cat >/root/auto_active_cluster <<EOF
#!/usr/bin/expect -f
spawn deploy_tools.py
set timeout -1
expect "1. Activate Cluster"
send "1\n"
expect "this operation will clear all the data"
send "Y\n"
expect "zh_CN"
send "zh_CN\n"
expect "1: Standard"
send "1\n"
expect "1: Erds Service"
send "1\n"
expect "IP List:"
send "1\n"
expect "Master Node IP"
send "Y\n"
expect "1. Activate Cluster"
send "\x03"
EOF

    chmod +x /root/auto_active_cluster
    echo "Prepare Finish"

    echo "---------------------------------------------------------------------------"

    echo "Start Active Cluster..."
    /root/auto_active_cluster

    echo && echo "---------------------------------------------------------------------------"

    echo "remove /root/auto_active_cluster..."
    rm -rf /root/auto_active_cluster
    echo "----------------------------------- END -----------------------------------"
}

download_url=$1
    echo "1 for ReplacePackage and 2 for active and 3 for ReplacePackage and Active and q to exit"
    selection=3
    case "$selection" in
    "1")
        replace_package $download_url
        ;;
    "2")
        active
        ;;
    "3")
        replace_package $download_url
        if [ "$?" != "0" ]; then
            exit 1
        fi
        active
        ;;
    "q")
        echo "exit"
        ;;
    *)
        echo "Wrong Selection!"
        ;;
    esac

