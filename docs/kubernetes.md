## 部署kubernetes
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

```
systemctl stop firewalld.service
systemctl disable firewalld.service

# 关闭swap交换分区
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
yes | cp /etc/fstab /etc/fstab_bak
cat /etc/fstab_bak |grep -v swap > /etc/fstab
```

```
# 卸载旧docker版本
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo
# Install Docker CE
yum install -y yum-utils device-mapper-persistent-data lvm2
### Add Docker repository.
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
```

```
## Install Docker CE.
yum install -y docker-ce-19.03.8 docker-ce-cli-19.03.8 containerd.io-1.2.13
# yum -y install docker-ce-19.03.4 docker-ce-cli-19.03.4 containerd.io-1.2.10
## Create /etc/docker directory.
mkdir /etc/docker
```

```
# Set up the Docker daemon
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
  ]
}
EOF
```

```
mkdir -p /etc/systemd/system/docker.service.d
# Restart Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
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
```

```
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
```

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet

systemctl daemon-reload
systemctl restart kubelet


## 二进制部署kubernetes

#### 自签CA颁发证书
```
# 1、使用cfssl自签证书
mkdir -p /opt/certs
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/bin/cfssl-certinfo
# 
chmod +x /usr/bin/cfssl*
```

```
# 2、创建CA证书请求文件（csr）
cat >> /opt/certs/ca-csr.json <<EOF
{
    "CN": "kubernetes-ca",
    "hosts": [
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "kubernetes",
            "OU": "dotpod"
        }
    ],
    "ca": {
        "expiry": "87600h"
    }
}
EOF
# 生成CA证书和私钥
cfssl gencert -initca /opt/certs/ca-csr.json | cfssljson -bare ca
```

```
cat >> /opt/certs/ca-config.json <<EOF
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "server": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
```

```
# 创建etcd证书请求文件
# 实际部署中,请修改"hosts"中Ip地址
cat >> /opt/certs/etcd-peer-csr.json <<EOF
{
    "CN": "k8s-etcd",
    "hosts": [
        "172.31.205.44",
        "172.31.205.45",
        "172.31.205.44"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "BeiJing",
            "L": "BeiJing",
            "O": "kubernetes",
            "OU": "dotpod"
        }
    ]
}
EOF
# 签发etcd证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcd-peer-csr.json |cfssljson -bare etcd
```



[kubernetes]
mkdir -p /opt/src
# 下载kubernetes二进制包
wget -c -P /opt/src https://dl.k8s.io/v1.16.15/kubernetes-server-linux-amd64.tar.gz

tar zxf /opt/src/kubernetes-server-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/kubernetes /opt/src/kubernetes-v1.16.15

# 下载etcd安装包
```
curl -L https://github.com/etcd-io/etcd/releases/download/v3.2.31/etcd-v3.2.31-linux-amd64.tar.gz -o /opt/src/etcd-v3.2.31-linux-amd64.tar.gz

tar zxf /opt/src/etcd-v3.2.31-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/etcd-v3.2.31-linux-amd64 /opt/src/etcd-v3.2.31
ln -s /opt/src/etcd-v3.2.31 /opt/src/etcd
# 创建存放etcd证书目录
mkdir -p /opt/src/etcd/cert/
```

# 创建etcd系统启动服务
```
mkdir -p /var/lib/etcd
cat >> /lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Server
Documentation=https://github.com/coreos
After=network.target
After=network-online.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/opt/src/etcd/etcd --name etcd1 \
  --listen-peer-urls https://172.31.205.44:2380 \
  --listen-client-urls https://172.31.205.44:2379,http://127.0.0.1:2379 \
  --quota-backend-bytes 8000000000 \
  --advertise-client-urls https://172.31.205.44:2379,http://127.0.0.1:2379 \
  --initial-cluster k8s-master=https://172.31.205.44:2380,k8s-master=https://172.31.205.45:2380,k8s-master=https://172.31.205.46:2380 \
  --data-dir /var/lib/etcd/ \
  --initial-advertise-peer-urls https://172.31.205.44:2380 \
  --ca-file /opt/src/etcd/cert/ca.pem \
  --cert-file /opt/src/etcd/cert/etcd.pem \
  --key-file /opt/src/etcd/cert/etcd-key.pem \
  --client-cert-auth \
  --trusted-ca-file /opt/src/etcd/cert/ca.pem \
  --peer-ca-file /opt/src/etcd/cert/ca.pem \
  --peer-cert-file /opt/src/etcd/cert/etcd.pem \
  --peer-key-file /opt/src/etcd/cert/etcd-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /opt/src/etcd/cert/ca.pem \
  --log-output stdout

TimeoutSec=0
RestartSec=2
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```

systemctl daemon-reload
systemctl restart etcd
systemctl enable etcd


