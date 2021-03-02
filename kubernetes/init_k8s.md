# 通过Kubeadm安装kubernetes v1.18.x

## 配置要求
> 至少3台`2核4G`的服务器
>
> CentOS 7.6/7.8

## 安装后软件版本
- Kubernetes v1.18.x
  - flannel (选择配置)
  - Calico 3.17.1（选择配置）
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
hostnamectl set-hostname --static xxxx

# hostname立即生效 执行 bash 即可
# 设置hostname解析
echo "127.0.0.1   $(hostname)" >> /etc/hosts
```

## 三、安装docker和kubelet
> 在 master 节点和 worker 节点都要执行

- [快速安装](../script/install_kubelet.sh)

> export REGISTRY_MIRROR=https://registry.cn-hangzhou.aliyuncs.com
>
> curl -sSL https://github.com/matt-pei/Handbook/raw/master/script/install_kubelet.sh | sh -s 1.18.9

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
# 将 ${1} 替换为 kubernetes 版本号，例如 1.18.9
yum install -y kubelet-1.18.9 kubeadm-1.18.9 kubectl-1.18.9

systemctl enable kubelet
systemctl start kubelet
```

## 四、初始化master节点

> 只在master上执行
>

- APISERVER_NAME 不能是 master 的 hostname
- APISERVER_NAME 必须全为小写字母、数字、小数点，不能包含减号
- POD_SUBNET 所使用的网段不能与 master节点/worker节点 所在的网段重叠。该字段的取值为一个 CIDR 值，如果您对 CIDR 这个概念还不熟悉，请仍然执行 export POD_SUBNET=10.100.0.1/16 命令,不做修改

### 1、配置环境变量
```
# master节点IP
export MASTER_IP=x.x.x.x
# 替换 apiserver.demo 为 您想要的 dnsName
export APISERVER_NAME=apiserver.demo
# Kubernetes容器组所在的网段
export POD_SUBNET=10.100.0.1/16
echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts
```
- 快速初始化（先完成配置环境变量）
- curl -sSL https://github.com/matt-pei/Handbook/raw/master/script/init_master.sh | sh -s 1.18.9


### 2、判断环境变量
```
if [ ${#POD_SUBNET} -eq 0 ] || [ ${#APISERVER_NAME} -eq 0 ]; then
  echo -e "\033[31;1m请确保您已经设置了环境变量 POD_SUBNET 和 APISERVER_NAME \033[0m"
  echo 当前POD_SUBNET=$POD_SUBNET
  echo 当前APISERVER_NAME=$APISERVER_NAME
  exit 1
fi
```

> 请将下面第6行的 ${1}替换成需要安装的版本号
```
rm -f ./kubeadm-config.yaml
cat <<EOF > ./kubeadm-config.yaml
---
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: v${1}
imageRepository: registry.aliyuncs.com/k8sxio
controlPlaneEndpoint: "${APISERVER_NAME}:6443"
networking:
  serviceSubnet: "10.96.0.0/16"
  podSubnet: "${POD_SUBNET}"
  dnsDomain: "cluster.local"

---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
EOF
```

```
# kubeadm init
echo "抓取镜像，请稍候..."
kubeadm config images pull --config=kubeadm-config.yaml

echo "初始化 Master 节点"
kubeadm init --config=kubeadm-config.yaml --upload-certs
```

```
# 配置 kubectl
rm -rf /root/.kube/
mkdir /root/.kube/
cp -i /etc/kubernetes/admin.conf /root/.kube/config
```

```
# 安装 calico 网络插件
# 参考文档 https://docs.projectcalico.org/v3.13/getting-started/kubernetes/self-managed-onprem/onpremises

echo "安装calico-3.17.1"
rm -f calico-3.17.1.yaml
kubectl create -f https://kuboard.cn/install-script/v1.20.x/calico-operator.yaml
wget https://kuboard.cn/install-script/v1.20.x/calico-custom-resources.yaml
sed -i "s#192.168.0.0/16#${POD_SUBNET}#" calico-custom-resources.yaml
kubectl create -f calico-custom-resources.yaml

# 查看 master 节点初始化结果
kubectl get nodes -o wide
```


## 五、初始化worker节点

### 1、先在master创建token
```
# 在master上执行
kubeadm token create --print-join-command
```
> 例如 (执行kubeadm token create的输出)
>
> kubeadm join apiserver.demo:6443 --token mpfjma.4vjjg8flqihor4vt     --discovery-token-ca-cert-hash sha256:6f7a8e40a810323672de5eee6f4d19aa2dbdb38411845a1bf5dd63485c43d303

> ⚠️注意
>
> 生成的token有效时间为 2 个小时,2小时内可以使用此 token 初始化任意数量的 worker 节点。


### 2、初始化worker节点
- 只在 worker 节点执行

```
# master节点IP
export MASTER_IP=x.x.x.x
# 替换 apiserver.demo 为 您想要的 dnsName
export APISERVER_NAME=apiserver.demo
echo "${MASTER_IP}    ${APISERVER_NAME}" >> /etc/hosts

# 加入集群（master上的token输出）
kubeadm join apiserver.demo:6443 --token mpfjma.4vjjg8flqihor4vt     --discovery-token-ca-cert-hash sha256:6f7a8e40a810323672de5eee6f4d19aa2dbdb38411845a1bf5dd63485c43d303
```

### 3、查看node节点信息
```
# 在 master 节点执行
# 查看node节点信息
kubectl get nodes -o wide

# 查看node节点信息
kubectl get nodes
```





