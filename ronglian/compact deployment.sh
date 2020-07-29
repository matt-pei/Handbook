#!/bin/bash
# Minicomputer deployment script

# 1、关闭selinux和firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld.service
systemctl stop firewalld.service
# 2、初始化磁盘（fdisk -l先查看磁盘）
parted /dev/sdb <<EOF
mklabel
gpt
mkpart
primary
ext4
1
1000G
quit
EOF
# 格式化分区
# 参考：https://docs.docker.com/storage/storagedriver/overlayfs-driver/
mkfs.xfs -f -n ftype=1 /dev/sdb
mkdir -pv /data
# 创建逻辑分区（磁盘同上）
pvcreate /dev/sda
vgcreate vgdata /dev/sda
# 此处将该卷组全部剩余空间划入本逻辑卷
lvcreate -l +100%FREE -n lvdata vgdata
# 格式化逻辑卷
mkfs.xfs -f /dev/vgdata/lvdata
# 设置开机自动挂载(手动)
echo "/dev/vgdata/lvdata      /data   xfs     defaults        0 0" >> /etc/fstab
mount -a && df -Th

# 3、调整内核参数
cat >> /etc/security/limits.conf <<EOF
root    soft    nofile  100001
root    hard    nofile  100002
*        soft    core        unlimited
*        hard    core        unlimited
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
gpadmin      hard    nproc       102400
gpadmin      hard    nproc       102400
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
kernel.shmmni = 409600
kernel.shmall = 400000000000
kernel.sem = 500 2048000 200 40960
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

# 4、安装时间服务器和需要的工具包
mkdir -pv /etc/yum.repos.d/repo.backup
mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/repo.backup
mv /etc/yum.repos.d/repo.backup/CentOS-Base* /etc/yum.repos.d/
# 下载阿里epel源
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum -y install vim wget net-tools htop pciutils epel-release tcpdump iptraf
yum -y install bash-completion chrony iotop sysstat
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

# 5、安装GPU驱动
# 更新内核和驱动所需要的依赖
yum update -y kernel && yum install -y kernel-devel-3.10.0 kernel-headers gcc && reboot
# 创建驱动目录并下载
mkdir -pv /opt/nvidia-drive/tesla
wget -c -P /opt/nvidia-drive http://cn.download.nvidia.com/XFree86/Linux-x86_64/440.82/NVIDIA-Linux-x86_64-440.82.run
# 禁用系统Nouveau驱动
sed -i "s/blacklist nvidiafb/#&/" /usr/lib/modprobe.d/dist-blacklist.conf
cat >> /usr/lib/modprobe.d/dist-blacklist.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
# 如在安装驱动的时候提示Nouveau相关可尝试使用下方补救方式
# 方式：一
# cat > /etc/modprobe.d/blacklist-nouveau.conf <<EOF
# blacklist nouveau
# options nouveau modeset=0
# EOF
# 方式：二
# cat > /etc/modprobe.d/blacklist.conf <<EOF
# blacklist nouveau
# EOF

# 备份系统initramfs镜像
mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bak
dracut /boot/initramfs-$(uname -r).img $(uname -r)
reboot
# 重启后查看系统Nouveau是否被禁用（没有任何输出）
lsmod | grep nouveau
# 安装驱动
sh /opt/nvidia-drive/NVIDIA-Linux-x86_64-440.82.run --kernel-source-path=/usr/src/kernels/3.10.0-1127.10.1.el7.x86_64/ -k $(uname -r)
# 查看GPU信息
nvidia-smi

# 6、安装docker服务
# 关闭swap交换分区
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
# 卸载旧docker版本
# https://docs.docker.com/install/linux/docker-ce/centos/
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo
# Install Docker CE
## Set up the repository
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum update -y && yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.8 \
  docker-ce-cli-19.03.8
# yum -y install docker-ce-19.03.4 docker-ce-cli-19.03.4 containerd.io-1.2.10

## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "graph": "/data/docker_store",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "insecure-registries" : ["registry.cloopen.net"],
  "live-restore": true
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# 7、安装nvidia-docker
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
yum install -y nvidia-container-toolkit
systemctl restart docker
# 测试GPU
docker run --rm --gpus all nvidia/cuda:10.0-base nvidia-smi
docker run --rm --gpus '"device=0"' nvidia/cuda:10.0-base nvidia-smi


# 5、下载Nvidia驱动
mkdir -pv /opt/nvidia-drive/tesla
# 请根据实际GPU型号选择性下载驱动版本（适用于2080Ti、1080Ti）
# wget -c -P /opt/nvidia-drive http://cn.download.nvidia.com/XFree86/Linux-x86_64/440.82/NVIDIA-Linux-x86_64-440.82.run
# wget -c -P /opt/nvidia-drive http://cn.download.nvidia.com/XFree86/Linux-x86_64/440.64/NVIDIA-Linux-x86_64-440.64.run
# wget -c -P /opt/nvidia-drive http://cn.download.nvidia.com/XFree86/Linux-x86_64/440.59/NVIDIA-Linux-x86_64-440.59.run
# wget -c -P http://cn.download.nvidia.com/XFree86/Linux-x86_64/450.57/NVIDIA-Linux-x86_64-450.57.run

# 适用于Tesla T4｜cuda 10.0
wget -c -P /opt/nvidia-drive/tesla http://cn.download.nvidia.com/tesla/410.129/NVIDIA-Linux-x86_64-410.129-diagnostic.run
# 适用于Tesla T4｜cuda 10.1
wget -c -P /opt/nvidia-drive/tesla http://cn.download.nvidia.com/tesla/418.126.02/NVIDIA-Linux-x86_64-418.126.02.run
# 适用于Tesla T4｜cuda 10.2
wget -c -P /opt/nvidia-drive/tesla http://cn.download.nvidia.com/tesla/440.64.00/NVIDIA-Linux-x86_64-440.64.00.run



# 容器启动命令
# 所有配置文件需提前创建好,否则容器挂载启动会生成目录
# <!-- # ES启动容器 -->
chmod 777 /data/huiyan/elastic/data/
docker pull elasticsearch:7.1.1
docker run -dit --restart=always \
      --memory=3G \
      --network host \
      --name es \
      -p 9200:9200 -p 9300:9300 \
      -v /etc/localtime:/etc/localtime:ro \
      -v /data/common/elastic/data:/usr/share/elasticsearch/data \
      -v /data/common/elastic/config:/usr/share/elasticsearch/config \
      192.168.181.194/cvhuiyan/elasticsearch:7.1.1
# 测试ES
curl -X GET "localhost:9200/?pretty"
# <!-- kibana启动容器 -->
docker pull kibana:7.1.1
docker run -dit --restart=always \
      --network host \
      --memory=2G \
      --name kibana \
      -p 5601:5601 \
      -e ELASTICSEARCH_URL=http://127.0.0.1:9200 \
      -v /data/common/kibana/config/kibana.yml:/usr/share/kibana/config/kibana.yml \
      -v /etc/localtime:/etc/localtime:ro \
      192.168.181.194/cvhuiyan/kibana:7.1.1
# <!-- # mysql启动容器 -->
# <!-- 修改数据库配置大小写 -->
docker pull mysql:5.7.29
docker run -dit --restart=always \
      --network=host \
      --memory=3G \
      --name mysql \
      -p 3306:3306 \
      -e TZ=Asia/Shanghai \
      -v /etc/localtime:/etc/localtime:ro \
      -v /data/common/mysql/config/my.cnf:/etc/mysql/my.cnf \
      -v /data/common/mysql/datadir:/var/lib/mysql \
      -e MYSQL_ROOT_PASSWORD=ytx@1234 \
      192.168.181.194/cvhuiyan/mysql:5.7.29
# <!-- # redis启动容器 -->
docker pull redis:5.0.8
docker run -dit --restart=always \
      --network host \
      --memory=1G \
      --name redis \
      -p 6379:6379 \
      -v /etc/localtime:/etc/localtime:ro \
      -v /data/common/redis/config/redis.conf:/usr/local/etc/redis/redis.conf \
      192.168.181.194/cvhuiyan/redis:5.0.8 \
      redis-server /usr/local/etc/redis/redis.conf
# <!-- # ws启动容器 -->
docker pull registry.cloopen.net/ws:2.4.1
docker run -dit --restart=always \
      --cpus=2 \
      --memory=3G \
      --network host \
      --name wsserver \
      -p 8884:8884 \
      -v /etc/localtime:/etc/localtime:ro \
      -v /data/common/wsserver/config/:/opt/wsserver/config/ \
      -v /data/common/wsserver/logs:/opt/wsserver/logs \
      -v /data/pictures:/opt/wsserver/pic/ \
      192.168.181.194/cvhuiyan/ws-server:v2.4.2
# <!-- # BS_pic启动容器 -->
docker pull registry.cloopen.net/bs:2.4.1
docker run -dit --restart=always \
      --cpus=2 \
      --memory=3G \
      --network host \
      --name bsserver \
      -p 8080:8080 \
      -v /etc/localtime:/etc/localtime:ro \
      -v /data/common/bsserver/config:/opt/bsserver/config \
      -v /data/common/bsserver/logs:/opt/bsserver/logs \
      -v /data/pictures:/opt/bsserver/pic/ \
      192.168.181.194/cvhuiyan/bs-server:v2.4.2
# <!-- # avt启动容器 -->
docker pull registry.cloopen.net/avt:2.4.1
docker run -dit --restart=always \
        --cpus=2 \
        --memory=3G \
        --network host \
        --name avtserver \
        -p 9989:9989 \
        -v /etc/localtime:/etc/localtime:ro \
        -v /data/common/avtserver/config:/opt/avtserver1.2.3/config \
        -v /data/common/avtserver/logs:/opt/avtserver1.2.3/logs \
        192.168.181.194/cvhuiyan/avt-server:v2.4.2
# <!-- # vs启动容器 -->
docker pull registry.cloopen.net/vs:2.4.1
docker run -dit --restart=always \
        --cpus=2 \
        --memory=5G \
        --network host \
        --name vsserver \
        -p 8989:8989 \
        -v /etc/localtime:/etc/localtime:ro \
        -v /data/common/vsserver/config:/opt/vsserver1.2.5/config \
        -v /data/common/vsserver/logs:/opt/vsserver1.2.5/logs \
        192.168.181.194/cvhuiyan/vs-server:v2.4.2
# <!-- aiserver -->
wget http://192.168.179.232:8000/ai_xxj.tar
docker load -i ./ai_xxj.tar
docker run -dit --gpus all \
      --network host \
      --restart=always \
      --cpus=2 \
      --memory=10G \
      --name=aiserver \
      -p 8891:8891 \
      -v /data/common/aiserver/config:/root/ai_server_c_muduo/config/ \
      -v /data/common/aiserver/logs:/root/ai_server_c_muduo/log/ \
      192.168.181.194/aiserver/ai-server:2.4.2.dev


# HealthCheck
HEALTHCHECK --interval=10s --timeout=5s --retries=3 CMD 

bs:
# curl -i http://192.168.177.238:8080/login -X POST --user 'lzd:123456' 2>&1 | grep 200 |awk '{print $2}'
# curl --fail http://192.168.177.238:8080/login -X POST --user 'lzd:123456' || exit 1
curl -sL -w "http_code:%{http_code} \n content_type:%{content_type}" -o /dev/null  http://localhost:8080/sys/user/infoData

ws:
# curl -i http://192.168.177.238:8884/result/1 2>&1 | grep 200 |awk '{print $2}'
# curl --fail http://192.168.177.238:8884/result/1 || exit 1
curl -sL -w "http_code:%{http_code} \n" -o /dev/null http://localhost:8884/result/1

ai:
# curl -i http://192.168.177.238:8891/cv/v1/healthCheck 2>&1 | grep 200 |awk '{print $2}'
# curl --fail http://192.168.177.238:8891/cv/v1/healthCheck || exit 1
curl -sL -w "http_code:%{http_code} \n" -o /dev/null http://localhost:8891/cv/v1/healthCheck

avt:
# curl -i http://192.168.177.238:9989/healthCheck 2>&1 | grep 200 | awk 'NR==1'|awk '{print $2}'
# curl --fail http://192.168.177.238:9989/healthCheck || exit 1 
curl -sL -w "http_code:%{http_code} \n" -o /dev/null http://localhost:9989/healthCheck

vs:
# curl -i http://192.168.177.238:8989/healthCheck 2>&1 | grep 200 | awk 'NR==1'|awk '{print $2}'
# curl --fail http://192.168.177.238:8989/healthCheck || exit 1
curl -sL -w "http_code:%{http_code} \n" -o /dev/null http://localhost:8989/healthCheck

