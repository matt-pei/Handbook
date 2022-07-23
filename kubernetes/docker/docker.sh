#!/bin/bash
set -e
# 1、系统初始化
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
# 关闭firewalld服务
systemctl stop firewalld.service
systemctl disable firewalld.service
# 关闭NetworkManager
systemctl stop NetworkManager
systemctl disable NetworkManager

# 创建data目录
mkdir -pv /data
# 2、安装常用工具
yum -y install vim wget net-tools htop pciutils epel-release tcpdump iptraf
yum -y install bash-completion chrony iotop sysstat bind-utils

## 2.1 配置时间服务 
cat > /etc/chrony.conf <<EOF
server ntp.aliyun.com iburst
stratumweight 0
driftfile /var/lib/chrony/drift
rtcsync
makestep 10 3
bindcmdaddress 127.0.0.1
bindcmdaddress ::1
keyfile /etc/chrony.keys
commandkey 1
generatecommandkey
logchange 0.5
logdir /var/log/chrony
EOF
# 启动chronyd服务
systemctl enable chronyd
systemctl start chronyd

# 3、关闭交换分区
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
# yes | cp /etc/fstab /etc/fstab_bak
# cat /etc/fstab_bak |grep -v swap > /etc/fstab

# 4、安装docker
# 卸载旧docker版本
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo

## 4.2 安装docker依赖
yum install -y yum-utils device-mapper-persistent-data lvm2
 
## 4.3 添加docker存储库
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
 
## 4.4 安装dokcer-ce
 yum install -y containerd.io-1.2.13 docker-ce-19.03.8 docker-ce-cli-19.03.8
 
## 4.5 配置docker配置文件
 mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "graph": "/data/docker_storage",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "registry-mirrors": ["https://9vmq4adx.mirror.aliyuncs.com"]
}
EOF
 
## 4.6 创建docker服务目录
mkdir -p /etc/systemd/system/docker.service.d

# 5、启动docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

