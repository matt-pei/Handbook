# 🛠 Deploy Kubernetes using Kubeadm

<img alt="kubeadm log" src="" width="100">

---

## Kubeadm部署集群
## 1、配置规划

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

# 安装指定版本
yum list kubeadm kubectl kubelet --showduplicates
yum -y install kubeadm-1.20.0 kubectl-1.20.0 kubelet-1.20.0
systemctl enable kubelet && systemctl start kubelet
```

```
kubeadm init --apiserver-advertise-address=172.25.188.66 \
             --image-repository registry.aliyuncs.com/google_containers \
             --pod-network-cidr=192.168.0.0/16

export KUBECONFIG=/etc/kubernetes/admin.conf

# 检查Kubernetes集群证书过期
kubeadm certs check-expiration
```

```
# 安装Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 安装Calico
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
```
