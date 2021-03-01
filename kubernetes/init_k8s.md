# 通过Kubeadm安装kubernetes v1.18.x

## 配置要求
> 至少3台`2核4G`的服务器
>
> CentOS 7.6/7.8

## 安装后软件版本
- Kubernetes v1.18.x
  - flannel (选择配置)
  - Calico 3.13.1（选择配置）
  - Nginx-ingress 1.5.5
- Docker 19.03.8

## 一、检查主机名
```
# 确认系统版本
cat /etc/redhat-release

# 查看主机名是否配置,不能使用 localhost 最为节点名称
hostname

# 确认系统非ARM架构
lscpu
```

## 二、修改hostname主机名
```
# 修改hostname
hostname set-hostname --static xxxx

# hostname立即生效 执行 bash 即可
# 设置hostname解析
echo "127.0.0.1   $(hostname)" >> /etc/hosts
```

## 三、安装docker和kubele
- curl -sSL https://github.com/matt-pei/Handbook/raw/master/script/install_kubelet.sh | sh -s 1.19.5
- [快速安装](../script/install_kubernetes.sh)

### 1、设置阿里云docker hub地址
```
export REGISTRY_MIRROR=https://registry.cn-hangzhou.aliyuncs.com
```
### 2、关闭selinux和firewalld
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld.service
systemctl stop firewalld.service
```

### 3、禁用swap分区
```
swapoff -a          # 临时关闭
yes | cp /etc/fstab /etc/fstab_bak
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
# cat /etc/fstab_bak |grep -v swap > /etc/fstab
```

### 4、安装docker
```
yum -y remove docker \
    docker-client \
    docker-client-latest \
    docker-common \
    docker-latest \
    docker-latest-logrotate \
    docker-logrotate \
    docker-selinux \
    docker-engine-selinux \
    docker-engine

# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo

### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum install -y containerd.io-1.2.13 docker-ce-19.03.8 docker-ce-cli-19.03.8

## Create /etc/docker directory.
mkdir /etc/docker
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
  "registry-mirrors": ["${REGISTRY_MIRROR}"]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
```

### 5、安装nfs-utils
```
# 安装 nfs-utils
# 必须先安装 nfs-utils 才能挂载 nfs 网络存储
yum install -y nfs-utils
```

### 6、修改配置
```
# 修改 /etc/sysctl.conf
sed -i "s#^net.ipv4.ip_forward.*#net.ipv4.ip_forward=1#g"  /etc/sysctl.conf
sed -i "s#^net.bridge.bridge-nf-call-ip6tables.*#net.bridge.bridge-nf-call-ip6tables=1#g"  /etc/sysctl.conf
sed -i "s#^net.bridge.bridge-nf-call-iptables.*#net.bridge.bridge-nf-call-iptables=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.all.disable_ipv6.*#net.ipv6.conf.all.disable_ipv6=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.default.disable_ipv6.*#net.ipv6.conf.default.disable_ipv6=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.lo.disable_ipv6.*#net.ipv6.conf.lo.disable_ipv6=1#g"  /etc/sysctl.conf
sed -i "s#^net.ipv6.conf.all.forwarding.*#net.ipv6.conf.all.forwarding=1#g"  /etc/sysctl.conf

echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.forwarding = 1"  >> /etc/sysctl.conf

# 执行命令以应用
sysctl -p
```

### 7、配置k8s源
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=http://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg
       http://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
```

### 8、安装kubelet
```
# 卸载旧版本
yum remove -y kubelet kubeadm kubectl

# 安装kubelet、kubeadm、kubectl
# 将 ${1} 替换为 kubernetes 版本号，例如 1.19.0
yum install -y kubelet-${1} kubeadm-${1} kubectl-${1}

systemctl enable kubelet
systemctl start kubelet
```





