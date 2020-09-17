# 部署kubernetes

<img alt="kubernetes logo" src=../images/kuernetes/name_blue.png>

---

kubeadm部署方式暂停更新...

请移步下方二进制部署,优先更新二进制部署

#### 1、关闭selinux和firewalld
```
# 官方说明目前暂为支持selinux,所以关闭
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

(待更新...)环境声明：作者使用3台机器部署 `Master(etcd-01/CA)` `node01(etcd-02)` `node02(etcd-03)` 实际部署根据需求合理配置

### 1、自签CA颁发证书
```
# 1、使用cfssl自签证书
mkdir -p /opt/kubernetes/pki
cd /opt/kubernetes/pki
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/bin/cfssl-certinfo
# 
chmod +x /usr/bin/cfssl*
```

```
# 2、创建CA证书请求文件（csr）
cat > /opt/kubernetes/pki/ca-csr.json <<EOF
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
            "ST": "Beijing",
            "L": "Beijing",
            "O": "kubernetes",
            "OU": "System"
        }
    ],
    "ca": {
        "expiry": "87600h"
    }
}
EOF

# 生成CA证书和私钥
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

至此CA证书颁发机构完成，

```
cat > /opt/kubernetes/pki/ca-config.json <<EOF
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

### 2、部署etcd集群

首先创建etcd的请求文件,此请求文件是在`CA`机器上来完成

```
# 1、创建etcd证书请求文件
# 实际部署中,请修改"hosts"参数中的etcd集群规划的 准确 ip地址(非Ip地址范围)
# 否则在启动etcd的时候会报证书相关错误
cat > /opt/kubernetes/pki/etcd-peer-csr.json <<EOF
{
    "CN": "k8s-etcd",
    "hosts": [
        "192.168.181.211",
        "192.168.181.212",
        "192.168.181.213"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Beijing",
            "L": "Beijing",
            "O": "kubernetes",
            "OU": "system"
        }
    ]
}
EOF

# 签发etcd证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcd-peer-csr.json | cfssljson -bare etcd
```

etcd采用集群模式(3台),所以分别在`master(etcd-1)` `node01(etcd-2)` `node02(etcd-3)`安装部署

```
# 2、下载etcd安装包
# 实际规划etcd集群至少为3台机器,集群方式下在所有机器上执行操作
mkdir -p /opt/src/
curl -L https://github.com/etcd-io/etcd/releases/download/v3.2.31/etcd-v3.2.31-linux-amd64.tar.gz -o /opt/src/etcd-v3.2.31-linux-amd64.tar.gz

# curl -L https://github.com/etcd-io/etcd/releases/download/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz

tar zxf /opt/src/etcd-v3.2.31-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/etcd-v3.2.31-linux-amd64 /opt/src/etcd-v3.2.31

# 为etcd做软链接,方便更新升级
ln -s /opt/src/etcd-v3.2.31 /opt/src/etcd

# 创建存放etcd证书目录
mkdir -p /opt/src/etcd/{pki,logs}
```

---

#### ⚠️ 系统启动服务文件中的ip地址需要手动去更改,因为每台机器的监听ip地址不同,涉及需要更改的参数如下：

#### --listen-peer-urls

#### --listen-client-urls

#### --advertise-client-urls

#### --initial-advertise-peer-urls

#### ⚠️ [可选项] 如果想使用supervisor方式托管etcd服务,请忽略下方第3步骤

1. [spuervisor启动etcd服务](./supervisor.md)

---

```
# 3、创建etcd系统启动服务
cat > /lib/systemd/system/etcd.service <<EOF
[Unit]
Description=Etcd Server
Documentation=https://github.com/coreos
After=network.target
Wants=network-online.target

[Service]
Type=notify
WorkingDirectory=/opt/src/etcd/
ExecStart=/opt/src/etcd/etcd --name etcd-01 \
  --listen-peer-urls https://192.168.181.211:2380 \
  --listen-client-urls https://192.168.181.211:2379,http://127.0.0.1:2379 \
  --quota-backend-bytes 8000000000 \
  --advertise-client-urls https://192.168.181.211:2379,http://127.0.0.1:2379 \
  --initial-cluster etcd-01=https://192.168.181.211:2380,etcd-02=https://192.168.181.212:2380,etcd-03=https://192.168.181.213:2380 \
  --data-dir /opt/src/etcd/data \
  --initial-advertise-peer-urls https://192.168.181.211:2380 \
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

# 启动etcd服务
systemctl daemon-reload
systemctl restart etcd
systemctl enable etcd
```


```
# 4、查看etcd集群健康状态
# /opt/src/etcd/etcdctl cluster-health
ln -s /opt/src/etcd/etcdctl /usr/bin/etcdctl
ln -s /opt/src/etcd/etcdctl /usr/local/sbin/
etcdctl cluster-health
member 26bb67943ff3802a is healthy: got healthy result from http://127.0.0.1:2379
member 68b27ec2be75f5c1 is healthy: got healthy result from http://127.0.0.1:2379
member ddae50d640aac69b is healthy: got healthy result from http://127.0.0.1:2379
cluster is healthy

# 查看etcd集群在线状态
/opt/src/etcd/etcdctl member list
26bb67943ff3802a: name=etcd2 peerURLs=https://172.31.205.45:2380 clientURLs=http://127.0.0.1:2379,https://172.31.205.45:2379 isLeader=false
68b27ec2be75f5c1: name=etcd3 peerURLs=https://172.31.205.46:2380 clientURLs=http://127.0.0.1:2379,https://172.31.205.46:2379 isLeader=false
ddae50d640aac69b: name=etcd1 peerURLs=https://172.31.205.44:2380 clientURLs=http://127.0.0.1:2379,https://172.31.205.44:2379 isLeader=true
```


### 3、安装部署kubernetes
#### 1、安装k8s-apiserver
```
# 1、[k8s-apiserver]
# 下载kubernetes二进制包
# wget -c -P /opt/src https://dl.k8s.io/v1.16.15/kubernetes-server-linux-amd64.tar.gz
curl -L https://dl.k8s.io/v1.16.15/kubernetes-server-linux-amd64.tar.gz -o /opt/src/kubernetes-server-linux-amd64.tar.gz
# curl -L https://dl.k8s.io/v1.18.9/kubernetes-server-linux-amd64.tar.gz -o /opt/src/kubernetes-server-linux-amd64.tar.gz

tar zxf /opt/src/kubernetes-server-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/kubernetes /opt/src/kubernetes-v1.16.15
ln -s /opt/src/kubernetes-v1.16.15 /opt/src/kubernetes

rm -rf /opt/src/kubernetes/server/bin/*.tar
rm -rf /opt/src/kubernetes/server/bin/*_tag
```

```
# 2、签发client证书
# apiserver在与etcd进行通信时，apiserver是客户端etcd是服务端，因此需要client证书。
cat > /opt/kubernetes/pki/client-csr.json <<EOF
{
    "CN": "k8s-node",
    "hosts": [
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Beijing",
            "L": "Beijing",
            "O": "kubernetes",
            "OU": "system"
        }
    ]
}
EOF

# 签发client证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json | cfssljson -bare client
```

```
# 3、签发apiserver证书
# 当其他客户端与apiserver进行通信时也需要TLS认证，此时apiserver为服务端证书。
cat > /opt/certs/apiserver-csr.json <<EOF
{
    "CN": "apiserver",
    "hosts": [
        "127.0.0.1",
        "192.168.181.194",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster",
        "kubernetes.default.svc.cluster.local"
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "ST": "Beijing",
            "L": "Beijing",
            "O": "kubernetes",
            "OU": "system"
        }
    ]
}
EOF

# 签发apiserver证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare apiserver
```

```
# 4、拷贝证书
# 创建存放证书目录
mkdir -p /opt/src/kubernetes/server/bin/{certs,conf}
# 配置apiserver日志审计
cat > /opt/src/kubernetes/server/bin/conf/audit.yaml <<EOF
apiVersion: audit.k8s.io/v1beta1 # This is required.
kind: Policy
# Don't generate audit events for all requests in RequestReceived stage.
omitStages:
  - "RequestReceived"
rules:
  # Log pod changes at RequestResponse level
  - level: RequestResponse
    resources:
    - group: ""
      # Resource "pods" doesn't match requests to any subresource of pods,
      # which is consistent with the RBAC policy.
      resources: ["pods"]
  # Log "pods/log", "pods/status" at Metadata level
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log", "pods/status"]

  # Don't log requests to a configmap called "controller-leader"
  - level: None
    resources:
    - group: ""
      resources: ["configmaps"]
      resourceNames: ["controller-leader"]

  # Don't log watch requests by the "system:kube-proxy" on endpoints or services
  - level: None
    users: ["system:kube-proxy"]
    verbs: ["watch"]
    resources:
    - group: "" # core API group
      resources: ["endpoints", "services"]

  # Don't log authenticated requests to certain non-resource URL paths.
  - level: None
    userGroups: ["system:authenticated"]
    nonResourceURLs:
    - "/api*" # Wildcard matching.
    - "/version"

  # Log the request body of configmap changes in kube-system.
  - level: Request
    resources:
    - group: "" # core API group
      resources: ["configmaps"]
    # This rule only applies to resources in the "kube-system" namespace.
    # The empty string "" can be used to select non-namespaced resources.
    namespaces: ["kube-system"]

  # Log configmap and secret changes in all other namespaces at the Metadata level.
  - level: Metadata
    resources:
    - group: "" # core API group
      resources: ["secrets", "configmaps"]

  # Log all other resources in core and extensions at the Request level.
  - level: Request
    resources:
    - group: "" # core API group
    - group: "extensions" # Version of group should NOT be included.

  # A catch-all rule to log all other requests at the Metadata level.
  - level: Metadata
    # Long-running requests like watches that fall under this rule will not
    # generate an audit event in RequestReceived.
    omitStages:
      - "RequestReceived"
EOF
```

```
# 5、创建apiserver系统启动服务
cat > /lib/systemd/system/kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
[Service]
ExecStart=/opt/src/kubernetes/server/bin/./kube-apiserver \
  --apiserver-count 1 \
  --enable-admission-plugins NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
  --bind-address 192.168.181.194 \
  --authorization-mode RBAC,Node \
  --enable-bootstrap-token-auth \
  --tls-cert-file /opt/src/kubernetes/server/bin/certs/apiserver.pem \
  --tls-private-key-file /opt/src/kubernetes/server/bin/certs/apiserver-key.pem \
  --requestheader-client-ca-file /opt/src/kubernetes/server/bin/certs/ca.pem \
  --client-ca-file /opt/src/kubernetes/server/bin/certs/ca.pem \
  --etcd-cafile /opt/src/kubernetes/server/bin/certs/ca.pem \
  --etcd-certfile /opt/src/kubernetes/server/bin/certs/client.pem \
  --etcd-keyfile /opt/src/kubernetes/server/bin/certs/client-key.pem \
  --etcd-servers https://192.168.181.194:2379,https://192.168.177.238:2379,https://192.168.176.107:2379 \
  --service-cluster-ip-range 10.10.0.0/16 \
  --service-node-port-range 3000-29999 \
  --service-account-key-file /opt/src/kubernetes/server/bin/certs/ca-key.pem \
  --target-ram-mb=1024
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path /data/logs/kubernetes/kube-apiserver/ \
  --audit-policy-file /opt/src/kubernetes/server/bin/conf/audit.yaml \
  --log-dir  /data/logs/kubernetes/kube-apiserver/ \
  --kubelet-client-certificate /opt/src/kubernetes/server/bin/certs/client.pem \
  --kubelet-client-key /opt/src/kubernetes/server/bin/certs/client-key.pem \
  --v=2
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
```



















### 查看服务器资源
```
# 查看cpu物理个数
cat /proc/cpuinfo | grep 'phy' | sort | uniq
address sizes	: 46 bits physical, 48 bits virtual
physical id	: 0
physical id	: 1
```

```
# 查看单个cpu物理核数
cat /proc/cpuinfo | grep 'cores' | uniq
cpu cores	: 12
```

```
# 查看cpu总共逻辑核数
cat /proc/cpuinfo | grep 'processor' | wc -l
48
```

```
# 查看cpu型号
cat /proc/cpuinfo | sort | uniq | grep 'model'
model		: 85
model name	: Intel(R) Xeon(R) Silver 4214 CPU @ 2.20GHz
```

```
# 查看服务器品牌
grep 'DMI' /var/log/dmesg
[    0.000000] DMI: Dell Inc. PowerEdge R940xa/0TF0V7, BIOS 2.3.10 08/15/2019
s

dmidecode | grep -A4 -i 'system information'
System Information
	Manufacturer: Dell Inc.
	Product Name: PowerEdge R940xa
	Version: Not Specified
	Serial Number: 1T13Z03
```

```
# 可以使用一下命令查使用CPU最多的10个进程     
ps -aux | sort -k3nr | head -n 10
# 可以使用一下命令查使用内存最多的10个进程     
ps -aux | sort -k4nr | head -n 10
```
