# Installation minimal 

set -e
# 1、关闭selinux和firewalld
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld.service
systemctl stop firewalld.service

# 2、调整内核参数
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

# 3、安装时间服务器和需要的工具包
# mkdir -pv /etc/yum.repos.d/repo.backup
# mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/repo.backup
# mv /etc/yum.repos.d/repo.backup/CentOS-Base* /etc/yum.repos.d/
# 下载阿里epel源
# wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
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

# 4、安装GPU驱动
# 更新内核和驱动所需要的依赖
yum update -y kernel && yum install -y kernel-devel-3.10.0 kernel-headers gcc
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



