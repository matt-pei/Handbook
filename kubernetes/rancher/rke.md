# RKE部署Kubernetes集群

## 一、系统基础配置
### 1、安装docker
#### 1、关闭防火墙
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
# 关闭firewalld服务
systemctl stop firewalld.service
systemctl disable firewalld.service
# 关闭NetworkManager
systemctl stop NetworkManager
systemctl disable NetworkManager
```
#### 2、关闭swap分区
```
# 关闭swap交换分区
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab

# 创建磁盘挂载目录
mkdir -pv /data

# 修改默认磁盘挂载
umount  /home

vim /etc/fstab
/dev/mapper/centos-home /data                   xfs     defaults        0 0
mount -a && df -Th
```
#### 3、安装常用工具
```
yum -y install vim wget htop tcpdump bash-completion chrony

vim /etc/hosts
10.2.7.17       k8s-master01
10.2.7.16       k8s-master02
10.2.7.15       k8s-master03
10.2.7.14       k8s-node01
```
#### 4、配置时间服务器
```
# 修改chrony配置文件
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
# 立即手工同步
chronyc -a makestep
```
#### 5、卸载旧版本docker
```
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo
```
#### 6、安装docker依赖
```
# Install Docker CE
## Set up the repository
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2
```
#### 7、添加存储库
```
### Add Docker repository.
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```
#### 8、安装docker-ce
```
## Install Docker CE.
yum -y install docker-ce-19.03.4 docker-ce-cli-19.03.4 containerd.io-1.2.10
```
#### 9、创建docker配置文件
```
## Create /etc/docker directory.
mkdir /etc/docker
mkdir -pv /data/docker_storage

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
#### 10、启动docker服务
```
systemctl daemon-reload && systemctl enable docker
systemctl start docker && systemctl status docker
```

## 二、RKE部署集群
### 1、准备RKE配置
#### 1、创建rke普通用户
```
# 创建普通用户
useradd rke
usermod -aG docker rke
```
#### 2、配置内核模块
```
# 配置内核参数
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF > /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.may_detach_mounts = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF

sysctl --system
```
#### 3、配置ipvs内核模块
```
# 
cat <<EOF > /etc/modules-load.d/ipvs.conf 
ip_vs
ip_vs_lc
ip_vs_wlc
ip_vs_rr
ip_vs_wrr
ip_vs_lblc
ip_vs_lblcr
ip_vs_dh
ip_vs_sh
ip_vs_fo
ip_vs_nq
ip_vs_sed
ip_vs_ftp
ip_vs_sh
nf_conntrack
ip_tables
ip_set
xt_set
ipt_set
ipt_rpfilter
ipt_REJECT
ipip
EOF

# 重载内核模块
systemctl enable --now systemd-modules-load.service
```
### 2、安装RKE部署集群
#### 1、下载RKE二进制安装包
>> RKE版本对安装支持的Kubernetes版本也不同
```
# 下载RKE 指定版本
wget -c https://github.com/rancher/rke/releases/download/v1.3.11/rke_linux-amd64
```
#### 2、重命名rke二进制
```
mv rke_linux-amd64 rke
# 添加可执行权限
chmod +x rke
cp rke /usr/local/bin
rke --version
```
#### 3、下载helm
```
wget https://get.helm.sh/helm-v3.9.0-linux-amd64.tar.gz -P /opt/src/
tar zxf /opt/src/helm-v3.9.0-linux-amd64.tar.gz -C /opt/src/
cd /opt/src/linux-amd64/
cp helm /usr/local/bin/
```
#### 4、准备rke配置yml文件
```
cat > cluster.yaml <<EOF
nodes:
  - address: 10.2.7.17
    hostname_override: k8s-master01
    internal_address:
    user: rke
    role:
      - controlplane
      - etcd
    port: 22
  - address: 10.2.7.16
    hostname_override: k8s-master02
    internal_address:
    user: rke
    role:
      - controlplane
      - etcd
      - worker
    port: 22
  - address: 10.2.7.15
    hostname_override: k8s-master03
    internal_address:
    user: rke
    role:
      - controlplane
      - etcd
      - worker
    port: 22
  - address: 10.2.7.14
    hostname_override: k8s-node01
    internal_address:
    user: rke
    role:
      - worker
    port: 22
# 定义kubernetes版本
kubernetes_version: v1.22.9-rancher1-1
ignore_docker_version: false
addon_job_timeout: 60
dns:
  provider: coredns
  upstreamnameservers:
  - 10.50.240.13
  - 168.63.129.16
  nodelocal:
    ip_address: "169.254.20.10"

#authentication:
#  strategy: x509
#  sans:
#    - "10.10.1.131"
#    - "ops-api-6443-c982614caf667afa.elb.cn-north-1.amazonaws.com.cn"

authorization:
    mode: rbac

services:
  etcd:
    backup_config:
      enabled: true
      interval_hours: 12
      retention: 6
    ## rke版本小于0.2.x或rancher版本小于2.2.0时使用
    snapshot: true
    creation: 5m0s
    retention: 24h

    # 扩展参数
    extra_args:
      # 240个小时后自动清理磁盘碎片,通过auto-compaction-retention对历史数据压缩后，后端数据库可能会出现内部碎片。内部碎片是指空闲状态的，能被后端使用但是仍然消耗存储空间，碎片整理过程将此存储空间释放回文>件系统
      auto-compaction-retention: 168 #(单位小时)
      # 修改空间配额为6442450944，默认2G,最大8G
      quota-backend-bytes: '6442450944'
  kubelet:
    extra_binds:
      - "/usr/libexec/kubernetes/kubelet-plugins:/usr/libexec/kubernetes/kubelet-plugins"
    cluster_domain: cluster.local
    # 内部DNS服务器地址
    # cluster_dns_server: 172.43.0.10
    # 禁用swap
    fail_swap_on: false
    extra_args:
      #root-dir: /srv/data/kubelet
      # 支持静态Pod。在主机/etc/kubernetes/目录下创建manifest目录，Pod YAML文件放在/etc/kubernetes/manifest/目录下
      feature-gates: RotateKubeletServerCertificate=true
      read-only-port: 10255
      #serverTLSBootstrap: true
      max-pods: "250"
      ## 密文和配置映射同步时间，默认1分钟
      sync-frequency: '3s'
      ## Kubelet进程可以打开的文件数（默认1000000）,根据节点配置情况调整
      max-open-files: '2000000'
      ## 与apiserver会话时的并发数，默认是10
      kube-api-burst: '30'
      ## 与apiserver会话时的 QPS,默认是5
      kube-api-qps: '15'
      ## kubelet默认一次拉取一个镜像，设置为false可以同时拉取多个镜像，
      ## 前提是存储驱动要为overlay2，对应的Dokcer也需要增加下载并发数
      serialize-image-pulls: 'false'
      ## 拉取镜像的最大并发数，registry-burst不能超过registry-qps ，
      ## 仅当registry-qps大于0(零)时生效，(默认10)。如果registry-qps为0则不限制(默认5)。
      registry-burst: '10'
      registry-qps: '0'
      cgroups-per-qos: 'true'
      cgroup-driver: 'systemd'
      # 节点资源预留
      enforce-node-allocatable: 'pods'
      system-reserved: 'cpu=0.25,memory=200Mi'
      kube-reserved: 'cpu=0.25,memory=500Mi'
      eviction-hard: 'memory.available<300Mi,nodefs.available<10%,imagefs.available<5%,nodefs.inodesFree<5%'
      eviction-soft: 'memory.available<500Mi,nodefs.available<20%,imagefs.available<10%,nodefs.inodesFree<10%'
      eviction-soft-grace-period: "memory.available=1m30s,nodefs.available=3m,nodefs.inodesFree=3m,imagefs.available=3m"
      eviction-max-pod-grace-period: '300'
      eviction-pressure-transition-period: '300s'
      node-status-update-frequency: 10s
      # 设置cAdvisor全局的采集行为的时间间隔，主要通过内核事件来发现新容器的产生。默认1m0s
      global-housekeeping-interval: 1m0s
      # 每个已发现的容器的数据采集频率。默认10s
      housekeeping-interval: 10s
      # 所有运行时请求的超时，除了长时间运行的 pull, logs, exec and attach。超时后，kubelet将取消请求，抛出错误，然后重试。(默认2m0s)
      runtime-request-timeout: 2m0s
      # 指定kubelet计算和缓存所有pod和卷的卷磁盘使用量的间隔。默认为1m0s
      volume-stats-agg-period: 1m0s
  kube-api:
    pod_security_policy: false
    always_pull_images: false
    extra_args:
      feature-gates: 'RemoveSelfLink=false'
      service-node-port-range: 0-65535
      default-watch-cache-size: 1500
      event-ttl: 1h0m0s
      max-requests-inflight: 800
      max-mutating-requests-inflight: 400
      kubelet-timeout: 5s
  kube-controller:
    extra_args:
      feature-gates: RotateKubeletServerCertificate=true
      node-monitor-period: '5s'
      node-monitor-grace-period: '20s'
      node-startup-grace-period: '30s'
      pod-eviction-timeout: '1m'
  kubeproxy:
    extra_args:
      proxy-mode: "ipvs"
      metrics-bind-address: "0.0.0.0"
      # 与kubernetes apiserver通信并发数,默认10
      kube-api-burst: 20
      # 与kubernetes apiserver通信时使用QPS，默认值5，QPS=并发量/平均响应时间
      kube-api-qps: 10
#monitoring:
#  provider: metrics-server
monitoring:
  provider: metrics-server
  update_strategy: # Available in v2.4
    strategy: RollingUpdate
    rollingUpdate:
      maxUnavailable: 3
#system_images:
#  metrics_server: registry.cn-hangzhou.aliyuncs.com/google_containers/metrics-server:v0.6.1
# 有几个网络插件可以选择：flannel、canal、calico，Rancher2默认canal
network:
  plugin: flannel
# 可以设置provider: none来禁用ingress controller
ingress:
  provider: none
  #options:
  #  proxy-body-size: "50m"
EOF
```
### 3、安装kubectl
#### 1、配置kubectl源
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```
#### 2、安装kubectl
```
yum -y install kubectl-1.22.9-0
```
### 4、配置kubectl
#### 1、创建.kube文件
```
mkdir .kube
```
#### 2、拷贝文件
```
cp /home/rke/kube_config_cluster.yml .kube/config
```









