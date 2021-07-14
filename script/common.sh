#!/bin/bash
# docker version: 19.03.3+
# docker-compose version: 1.27.0+

set +e
set -o noglob


# Set Colours
bold=$(tput bold)
underline=$(tput sgr 0 1)
reset=$(tput sgr0)  # 关闭所有属性

red=$(tput setaf 1)     # setaf 使用ANSI转义设置前景色
green=$(tput setaf 76)
white=$(tput setaf 7)
tan=$(tput setaf 202)
blue=$(tput setaf 25)


underline() { printf "${underline}${bold}%s${reset}\n" "$@"
}
h1() { printf "${underline}${bold}${blue}%s${reset}\n" "$@"
}
h2() { printf "${underline}${bold}${white}%s${reset}\n" "$@"
}
debug() { printf "${white}%s${reset}\n" "$@"
}
info() { printf "${white}➜ %s${reset}\n" "$@"
}
sucess() { printf "${green}✔ %s${reset}\n" "$@"
}
error() { printf "${red}✖ %s${reset}\n" "$@"
}
warn() { printf "${tan}➜ %s${reset}\n" "$@"
}
bold() { printf "${bold}%s${reset}\n" "$@"
}
note() { printf "\n${underline}${bold}${blue}Note:${reset} ${blue}%s${reset}\n" "$@"
}

set -e

function check_nvidia {
    if ! nvidia-smi &> /dev/null
    then
        error "Need to install Nvidia device first and run this script again."
        exit 1
    fi
}

function check_docker {
    if ! docker --version &> /dev/null
    then
        error "Need to install docker(19.03.3+) first and run this script again."
        exit 1
    fi

    # docker has been installed and check its version
    if [[ $(docker --version) =~ (([0-9]+)\.([0-9]+)\.([0-9]*)) ]]
    then
        docker_version=${BASH_REMATCH[1]}
        docker_version_part1=${BASH_REMATCH[2]}
        docker_version_part2=${BASH_REMATCH[3]}
        docker_version_part3=${BASH_REMATCH[4]}

        note "docker version: $docker_version"
        # Determine the Docker version
        # if [ "$docker_version_part1" -lt 19 ] || ([ "$docker_version_part1" -eq 19 ] && [ "$docker_version_part2" -lt 3 ] && [ "$docker_version_part3" -lt 3 ])
        if [ "$docker_version_part1" -lt 17 ] || ([ "$docker_version_part1" -eq 17 ] && [ "$docker_version_part2" -lt 6 ])
        then
            error "Need to upgrade docker package to 19.03.3+."
            exit 1
        fi
    else
        error "Failed to parse docker version."
        exit 1
    fi
}

function check_dockercompose {
    if ! docker-compose --version &> /dev/null
    then
        error "Need to install docker-compose(1.27.0+) by yourself first and run this script again."
        exit 1
    fi
    # docker-compose has been installed, check its version
    # if [[ $(docker-compose --version) =~ (([0-9]+)\.([0-9]+)\.([0-9]*)) ]]
    if [ "$docker_compose_version_part1" -lt 1 ] || ([ "$docker_compose_version_part1" -eq 1 ] && [ "$docker_compose_version_part2" -lt 27 ])
    then
        docker_compose_version=${BASH_REMATCH[1]}
        docker_compose_version_part1=${BASH_REMATCH[2]}
        docker_compose_version_part2=${BASH_REMATCH[3]}

        note "docker-compose version: $docker_compose_version"
        # Determine the docker-compose version
        # if [ "$docker_compose_version_part1" -lt 1 ] || ([ "$docker_compose_version_part1" -eq 1 ] && [ "$docker_compose_version_part2" -lt 27 ])
        if [ "$docker_version_part1" -lt 17 ] || ([ "$docker_version_part1" -eq 17 ] && [ "$docker_version_part2" -lt 6 ])
        then
            error "Need to upgrade docker-compose package to 1.27.0+."
            exit 1
        fi
    else
        error "Failed to parse docker-compose version."
        exit 1
    fi
}

function initialize {
    # 关闭selinux和firewalld
    setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld.service
systemctl stop firewalld.service
#启动防火墙
systemctl restart firewalld
iptables -F
#开机自启
systemctl enable firewalld
#开启80，28092，22，1935的tcp端口
firewall-cmd --zone=public --add-port=80/tcp
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=28092/tcp
firewall-cmd --zone=public --add-port=28092/tcp --permanent
firewall-cmd --zone=public --add-port=1935/tcp
firewall-cmd --zone=public --add-port=1935/tcp --permanent
firewall-cmd --zone=public --add-port=22/tcp
firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --reload
# 关闭NetworkManager
systemctl stop NetworkManager
systemctl disable NetworkManager
# 优化内核参数
cat >> /etc/security/limits.conf <<EOF
root    soft    nofile  100001
root    hard    nofile  100002
*        soft    core        10240
*        hard    core        10240
*        soft    data        unlimited
*        hard    data        unlimited
*        soft    fsize       unlimited
*        hard    fsize       unlimited
*        soft    memlock     unlimited
*        hard    memlock     unlimited
*        soft    nofile      1024000
*        hard    nofile      1024000
*        soft    rss         unlimited
*        hard    rss         unlimited
*        soft    stack       8194
docker      soft    nproc       102400
docker      hard    nproc       102400
*        soft    locks       unlimited
*        hard    locks       unlimited
*        soft    sigpending  unlimited
*        hard    sigpending  unlimited
*        soft    msgqueue    unlimited
*        hard    msgqueue    unlimited
EOF
cat >> /etc/sysctl.conf <<EOF
kernel.shmmax = 50000000000
#kernel.shmmni = 409600
kernel.shmall = 400000000000
kernel.sem = 500 20480 200 4096
kernel.sysrq = 1
kernel.core_uses_pid = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.msgmni = 2048
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.tcp_max_syn_backlog = 4096
net.ipv4.conf.all.arp_filter = 1
net.ipv4.ip_local_port_range = 10000 65535
net.core.netdev_max_backlog = 10000
net.core.rmem_max = 2097152
net.core.wmem_max = 2097152
#vm.overcommit_memory = 2
#vm.swappiness = 10
vm.zone_reclaim_mode = 0
vm.dirty_expire_centisecs = 500
vm.dirty_writeback_centisecs = 100
vm.dirty_background_ratio = 0
vm.dirty_ratio = 0
vm.dirty_background_bytes = 1610612736
vm.dirty_bytes = 4294967296
# ES配置
vm.max_map_count=262144
EOF
# 执行命令生效
sysctl -p
# 安装时间服务器和需要的工具包
yum -y install vim wget net-tools htop pciutils epel-release tcpdump
yum -y install bash-completion chrony iotop sysstat iptables-services
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
systemctl enable chronyd
systemctl start chronyd
# 立即手工同步
chronyc -a makestep
# 配置域名解析
cat >> /etc/hosts <<EOF

127.0.0.1   cv.mysql.management.com
127.0.0.1   cv.redis.management.com
127.0.0.1   cv.nginx.management.com
127.0.0.1   cv.kibana.management.com
127.0.0.1   cv.elastic.management.com
127.0.0.1   cv.aiserver.management.com
127.0.0.1   cv.cm-server.management.com
127.0.0.1   cv.up-server.management.com
127.0.0.1   cv.device-server.management.com
127.0.0.1   cv.device-agent.management.com
EOF

pic_dir=/data/pictures

if [ ! -d $pic_dir ]; then
    mkdir -p $pic_dir
fi
}

function docker_install {
    # 关闭swap交换分区
    swapoff -a          # 临时关闭
    # vim /etc/fstab    # 永久关闭,注释swap行
    sed -i 's/.*swap.*/#&/' /etc/fstab
    # 关闭NetworkManager
    # systemctl stop NetworkManager.service
    # systemctl disable NetworkManager.service
    # 卸载旧docker版本
    yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
    # 删除旧docker存储库
    rm -rf /etc/yum.repos.d/docker*.repo
    
    # Install required packages.
    yum install -y yum-utils device-mapper-persistent-data lvm2
    # Add Docker repository.
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    # Install Docker CE.
    yum install -y containerd.io-1.2.13 docker-ce-19.03.8 docker-ce-cli-19.03.8
    
    # Create /etc/docker directory.
    if [ ! -d $docker_dir ]; then
        mkdir -p $docker_dir
    fi
    # Setup daemon
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
  "insecure-registries" : ["192.168.176.230:8090","8.131.240.247:8090"],
  "registry-mirrors": ["https://g427vmjy.mirror.aliyuncs.com"],
  "live-restore": true
}
EOF

docker_service_dir=/etc/systemd/system/docker.service.d
if [ ! -f $docker_service_dir ]; then
    mkdir -p $docker_service_dir
fi
# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
# 安装docker-compose
compose_dir=/usr/local/bin/docker-compose
if [ ! -f $compose_dir ]; then
    curl -L "https://github.com/docker/compose/releases/download/2.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi
}

function nvidia_docker {
    # 此步骤需提前安装好nvidia驱动才可以正常使用GPU
    # 安装nvidia-docker
    distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
    curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
    yum install -y nvidia-container-toolkit
    systemctl restart docker
    # 测试GPU
    docker run --rm --gpus all nvidia/cuda:10.0-base nvidia-smi
    docker run --rm --gpus '"device=0"' nvidia/cuda:10.0-base nvidia-smi
}

function jdk_install {
    # 移动配置文件到制定目录下
    data_dir=/data/
    if [ ! -d $data_dir ]; then
        mkdir -p $data_dir
    fi

    common_dir=/data/aibox-common
    if [ -d $common_dir ];then
        rm -rf $common_dir && mv aibox-common /data/
    else
        mv aibox-common /data/
    fi

    # 安装jdk环境
    src_dir=/opt/src
    if [ ! -d $src_dir ]; then
        mkdir -p $src_dir
    fi
    tar zxf /data/aibox-common/package/jdk-8u241-linux-x64.tar.gz -C /opt/src
    sed -i '10i JAVA_HOME=/opt/src/jdk1.8.0_241' /etc/profile
    sed -i '11i PATH=$PATH:$JAVA_HOME/bin:$JRE_HOME/bin' /etc/profile
    source /etc/profile
    # 配置up-server服务
    tar zxf /data/aibox-common/package/device-up-server-2.0.3.0.tar.gz -C /data/aibox-common/package/
    upserver_file=/lib/systemd/system/up-server.service
    if [ ! -f $upserver_file ]; then
        cp -r /data/aibox-common/package/device-up-server/up-server.service /lib/systemd/system/
    fi
    systemctl enable up-server
    systemctl start up-server
    # 开启docker API
    sed -i 's/^ExecStart.*/#&/' /lib/systemd/system/docker.service
    sed -i '15i ExecStart=/usr/bin/dockerd -H tcp://0.0.0.0:2375 -H unix://var/run/docker.sock -H fd:// --containerd=/run/containerd/containerd.sock' /lib/systemd/system/docker.service
}



rm -rf /usr/bin/docker-compose
rm -rf /usr/lib/systemd/system/docker.service
rm -rf /etc/docker
vi /etc/hosts
vi /etc/sysctl.conf
vi /etc/security/limits.conf
