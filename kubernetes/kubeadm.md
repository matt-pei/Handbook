# 🛠 Deploy Kubernetes using Kubeadm

<img alt="kubeadm log" src="./../images/kuernetes/kubeadm-stacked-color.png" width="100">

---

## Kubeadm部署集群
## 1、配置规划
|    角色     |      IP       |                              组件                              |
| :---------: | :-----------: | :------------------------------------------------------------: |
| k8s-master  | 172.25.188.69 | kube-apiserver、kube-controller-manager、kube-scheduller、etcd |
| k8s-node001 | 172.25.188.70 |                  kubelet、kube-proxy、docker                   |
| k8s-node002 | 172.25.188.71 |                  kubelet、kube-proxy、docker                   |

## 2、在开始之前
- 1、设置主机名
```
# master
hostnamectl set-hostname --static k8s-master && bash
# node01
hostnamectl set-hostname --static k8s-node001 && bash
# node02
hostnamectl set-hostname --static k8s-node002 && bash

# 显示当前主机名设置
hostnamectl status
# 设置 hostname 解析
echo "127.0.0.1   $(hostname)" >> /etc/hosts
# 设置集群主机名解析（ALL）
cat >> /etc/hosts <<EOF
172.25.188.69   k8s-master
172.25.188.70   k8s-node001
172.25.188.71   k8s-node002
EOF
```
- 2、关闭防火墙
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
- 3、在master配置免密登录
```
# master生成密钥
ssh-keygen -t rsa
for i in k8s-node{001,002};do ssh-copy-id -i ~/.ssh/id_rsa.pub $i;done
```
- 4、安装常用工具
```
# 下载repo源
wget -O /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-7.repo
# 缓存
yum makecache
# 下载epel源
mkdir -p /etc/yum.repos.d/backup
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/backup
mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/backup
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```
```
yum -y install vim wget htop pciutils sysstat epel-release
yum -y install chrony net-tools bash-completion iptables-services
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
- 5、配置iptables网桥
```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
```

## 3、安装容器运行时
- 1、关闭swap分区
```
# 关闭swap交换分区
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
# 关闭NetworkManager
# systemctl stop NetworkManager.service
# systemctl disable NetworkManager.service
```
- 2、卸载旧dokcer版本
```
# 卸载旧docker版本
# https://docs.docker.com/install/linux/docker-ce/centos/
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo
```
- 3、设置存储库
```
### Install required packages.
yum install -y yum-utils device-mapper-persistent-data lvm2

### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE.
yum install -y containerd.io-1.2.13 docker-ce-19.03.8 docker-ce-cli-19.03.8
# yum -y install docker-ce-19.03.4 docker-ce-cli-19.03.4 containerd.io-1.2.10
```
- 4、创建docker配置文件
```
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
  "registry-mirrors": ["https://9vmq4adx.mirror.aliyuncs.com"]
}
EOF
# 启动docker服务
mkdir -p /etc/systemd/system/docker.service.d
# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
```

## 4、安装Kubeadm
- 1、配置存储库
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
- 2、安装kubeadm
```
# 安装指定版本
yum list kubeadm kubectl kubelet --showduplicates
yum -y install kubeadm-1.19.13 kubelet-1.19.13 kubectl-1.19.13
# yum -y install kubeadm-1.20.9 kubectl-1.20.9 kubelet-1.20.9
systemctl enable kubelet && systemctl start kubelet
```
- 3、初始化集群
> 仅在master上执行
>
> apiserver-advertise-address参数根据实际Ip配置
```
kubeadm init --apiserver-advertise-address=172.25.188.66 --image-repository registry.aliyuncs.com/google_containers --pod-network-cidr=192.168.0.0/16
# kubeadm init --apiserver-advertise-address=172.25.188.66 \
             --image-repository registry.aliyuncs.com/google_containers \
             --pod-network-cidr=192.168.0.0/16

sed -i '10i export KUBECONFIG=/etc/kubernetes/admin.conf' /etc/profile
source /etc/profile
# 检查Kubernetes集群证书过期
kubeadm certs check-expiration
# kubernetes v1.20版本以下使用此命令
kubeadm alpha certs check-expiration
```
```
### kubectl命令补全
yum -y install bash-completion
kubectl completion -h
# 临时生效
source <(kubectl completion bash)
# 永久生效
echo 'source <(kubectl completion bash)' >>~/.bashrc
# echo "source <(kubectl completion bash)" >> /root/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
```

- 4、安装网络插件
```
# 安装Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
# 安装Calico
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
```
- 5、配置资源信息
```
# 查看节点label
kubectl get nodes --show-labels
# 更改node节点label
kubectl label node k8s-nodexxx node-role.kubernetes.io/node=

kubectl get nodes
```

## 5、删除节点
```
# 1、排出一个节点
kubectl drain <node name> --delete-local-data --force --ignore-daemonsets
# 2、删除节点
kubectl delete node <node name>
# 3、重制节点
kubeadm reset
# 4、删除节点信息
systemctl stop kubelet
systemctl stop docker
rm -rf /var/lib/cni
rm -rf /var/lib/kubelet/
rm -rf /etc/cni/
rm -rf /etc/kubernetes
ifconfig cni0 down
ifconfig flannel.1 down
ifconfig docker0 down
ip link delete cni0
ip link delete flannel.1
iptables -F && iptables -t nat -F
iptables -t mangle -F && iptables -X
ipvsadm -C
systemctl start docker
```