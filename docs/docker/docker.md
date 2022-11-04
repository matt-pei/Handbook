# 安装docker

## 1、系统初始化
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
# 关闭firewalld服务
systemctl stop firewalld.service
systemctl disable firewalld.service
```
### 1.1 创建docker存放目录
```
# 创建data目录
mkdir -pv /data/docker_storage
```

## 2、安装常用工具
```
# 安装常用工具
yum -y install vim wget net-tools htop pciutils epel-release tcpdump iptraf
yum -y install bash-completion chrony lrzsz iotop sysstat bind-utils
```
### 2.1 配置时间服务
```
# 启动时间服务器
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
```

## 3、关闭交换分区
```
# 关闭swap交换分区
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
# yes | cp /etc/fstab /etc/fstab_bak
# cat /etc/fstab_bak |grep -v swap > /etc/fstab
```

## 4、安装docker
### 4.1 先卸载旧版docker
```
# 卸载旧docker版本
# https://docs.docker.com/install/linux/docker-ce/centos/
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo
```
### 4.2 安装docker依赖
```
# Install Docker CE
## Set up the repository
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2
```
### 4.3 添加docker存储库
```
### Add Docker repository.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```
### 4.4 安装dokcer-ce
```
## Install Docker CE.
yum install -y containerd.io-1.2.13 docker-ce-19.03.8 docker-ce-cli-19.03.8
# yum -y install docker-ce-19.03.4 docker-ce-cli-19.03.4 containerd.io-1.2.10
```
### 4.5 配置docker配置文件
```
## Create /etc/docker directory.
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
  "registry-mirrors": ["https://g427vmjy.mirror.aliyuncs.com"]
}
EOF
```
### 4.6 创建docker服务目录
```
mkdir -p /etc/systemd/system/docker.service.d
```

## 5、启动docker
```
# Restart Docker
systemctl daemon-reload && systemctl enable docker
systemctl restart docker && systemctl status docker
```

> 非必要安装
```
# 安装docker-compose
curl -L "https://github.com/docker/compose/releases/download/v2.12.1/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
```
