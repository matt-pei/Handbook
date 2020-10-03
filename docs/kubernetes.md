# 部署Kubernetes集群

<img alt="kubernetes logo" src="../images/kuernetes/name_blue.png" />

---

## 二进制部署Kubernetes集群
## 1、生产环境k8s平台架构

- 单master集群

<img alt="k8s架构图" src="../images/kuernetes/eb67ab07dc1340bba5c654612791477c.jpeg" width="400" height="250" />

- 多master集群（HA）

<img alt="k8s架构图" src="../images/kuernetes/20191008-02.png" width="400" height="400" />

## 2、服务器规划
| 角色 | IP | 组件 |
| :----:| :----: | :----: |
| k8s-master | 192.168.10.222 | kube-apiserver kube-controller-manager kube-scheduller etcd01 |
| k8s-node01 | 192.168.10.223 | kubelet kube-proxy docker etcd02 |
| k8s-node01 | 192.168.10.224 | kubelet kube-proxy docker etcd03 |

## 3、系统初始化设置
- 1、设置主机名
```
# 警告：请分别设置对应的主机名
hostnamectl set-hostname --static k8s-master && bash
hostnamectl set-hostname --static k8s-node01 && bash
hostnamectl set-hostname --static k8s-node02 && bash

# 显示当前主机名设置
hostnamectl status
# 设置 hostname 解析
echo "127.0.0.1   $(hostname)" >> /etc/hosts
# 设置集群主机名解析（ALL）
echo "192.168.10.222   k8s-master" >> /etc/hosts
echo "192.168.10.223   k8s-node01" >> /etc/hosts
echo "192.168.10.224   k8s-node02" >> /etc/hosts
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
- 3、安装常用工具
```
yum -y install vim wget net-tools htop pciutils epel-release tcpdump iptraf
yum -y install bash-completion chrony lrzsz iotop sysstat bind-utils
# 配置时间服务
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
```
- 4、配置免密登陆
```
# master生成密钥
ssh-keygen -t rsa
ssh-copy-id -i ~/.ssh/id_rsa.pub  root@k8s-node01
ssh-copy-id -i ~/.ssh/id_rsa.pub  root@k8s-node02
```
> ssh-keygen -t rsa -P ''
> 
> -P表示密码，-P就表示空密码，也可以不用-P参数，这样就需要输入三次回车，用-P就输入一次回车。

## 4、自签CA颁发证书
### 4.1、安装cfssl工具
```
mkdir -p /opt/kubernetes/pki
cd /opt/kubernetes/pki
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/bin/cfssl-certinfo
# 添加执行权限
chmod +x /usr/bin/cfssl*
```
### 4.2、生成CA证书
#### 4.2.1 创建CA证书请求文件（csr）
```
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
#### 4.2.2 创建基于根证书的config配置文件

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

## 5、部署etcd集群
 
> 首先创建etcd的请求文件,此请求文件是在`CA`机器上创建

### 5.1 创建etcd证书请求文件

> 🚨警告：请修改`hosts`参数中ip地址(运行etcd的服务,非ip地址段)
>
> 否则在启动etcd的时候会报证书相关错误

```
cat > /opt/kubernetes/pki/etcd-peer-csr.json <<EOF
{
    "CN": "k8s-etcd",
    "hosts": [
        "192.168.10.221",
        "192.168.10.222",
        "192.168.10.223",
        "192.168.10.224",
        "192.168.10.225"
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
    ]
}
EOF
# 签发etcd证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcd-peer-csr.json | cfssljson -bare etcd
```

> etcd采用集群模式(3台),所以分别在`master(etcd-01)` `node01(etcd-02)` `node02(etcd-03)`安装部署

### 5.2 下载etcd安装包
- 实际规划etcd集群至少为3台机器,集群方式下在所有机器上执行操作
  - [默认使用github下载](https://github.com/etcd-io/etcd/releases/download/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz)
```
mkdir -p /opt/src/
curl -L https://github.com/etcd-io/etcd/releases/download/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz

tar zxf /opt/src/etcd-v3.3.25-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/etcd-v3.3.25-linux-amd64 /opt/src/etcd-v3.3.25
# 为etcd做软链接,方便更新升级
ln -s /opt/src/etcd-v3.3.25 /opt/src/etcd
# 创建存放etcd证书目录
mkdir -p /opt/src/etcd/{pki,logs}
```
#### 5.2.1 华为源加速下载
```
curl -L https://mirrors.huaweicloud.com/etcd/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz

curl -L https://mirrors.huaweicloud.com/etcd/v3.2.31/etcd-v3.2.31-linux-amd64.tar.gz -o /opt/src/etcd-v3.2.31-linux-amd64.tar.gz
```

### 5.3 配置etcd
#### 5.3.1 拷贝证书到node节点
```
# 3、拷贝证书
# master
cp /opt/kubernetes/pki/ca.pem /opt/src/etcd/pki/
cp /opt/kubernetes/pki/etcd.pem /opt/src/etcd/pki/
cp /opt/kubernetes/pki/etcd-key.pem /opt/src/etcd/pki/
# node01
scp /opt/kubernetes/pki/ca.pem k8s-node01:/opt/src/etcd/pki/
scp /opt/kubernetes/pki/etcd.pem k8s-node01:/opt/src/etcd/pki/
scp /opt/kubernetes/pki/etcd-key.pem k8s-node01:/opt/src/etcd/pki/
# node02
scp /opt/kubernetes/pki/ca.pem k8s-node02:/opt/src/etcd/pki/
scp /opt/kubernetes/pki/etcd.pem k8s-node02:/opt/src/etcd/pki/
scp /opt/kubernetes/pki/etcd-key.pem k8s-node02:/opt/src/etcd/pki/
```

> 🚨警告：系统启动服务文件中的ip地址需要手动去更改,因为每台机器的监听ip地址不同,需要更改的参数如下：
- --listen-peer-urls
- --listen-client-urls
- --advertise-client-urls
- --initial-advertise-peer-urls

> [可选项] 如果想使用supervisor方式启动etcd和kubernetes组件服务,请点击跳转“使用spuervisor启动etcd”并忽略下方 “5.3.3 创建etcd系统服务”
>  
> 建议配置system和supervisor两个启动服务配置,保证服务启动可靠性
- 1、[使用spuervisor启动etcd](./supervisor.md)

#### 5.3.2 添加etcd配置文件
> 🚨警告：修改`ETCD_NAME`和`涉及ip`等参数
```
mkdir -pv /etc/kubernetes/etcd/
mkdir -pv /data/kubernetes/etcd/data/
cat > /etc/kubernetes/etcd/etcd.conf <<EOF
#[Member]
ETCD_NAME="etcd-01"
ETCD_DATA_DIR="/data/kubernetes/etcd/data/"
ETCD_LISTEN_PEER_URLS="https://192.168.10.222:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.222:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.222:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.222:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://192.168.10.222:2380,etcd-02=https://192.168.10.223:2380,etcd-03=https://192.168.10.224:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

#[Certs]
CA_FILE="/opt/src/etcd/pki/ca.pem"
ETCD_CERT_FILE="/opt/src/etcd/pki/etcd.pem"
ETCD_KEY_FILE="/opt/src/etcd/pki/etcd-key.pem"
EOF
```
#### 5.3.3 创建etcd系统服务
```
# EnvironmentFile参数引用etcd配置文件
# vim /lib/systemd/system/etcd.service
cat > /lib/systemd/system/etcd.service <<\EOF
[Unit]
Description=Etcd Server
Documentation=https://github.com/coreos
After=network.target
Wants=network-online.target

[Service]
Type=notify
EnvironmentFile=/etc/kubernetes/etcd/etcd.conf
ExecStart=/opt/src/etcd/etcd --name=${ETCD_NAME} \
  --data-dir=${ETCD_DATA_DIR} \
  --quota-backend-bytes=8000000000 \
  --listen-peer-urls=${ETCD_LISTEN_PEER_URLS} \
  --listen-client-urls=${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
  --advertise-client-urls=${ETCD_LISTEN_CLIENT_URLS},http://127.0.0.1:2379 \
  --initial-cluster=${ETCD_INITIAL_CLUSTER} \
  --initial-advertise-peer-urls=${ETCD_INITIAL_ADVERTISE_PEER_URLS} \
  --ca-file=/opt/src/etcd/pki/ca.pem \
  --cert-file=/opt/src/etcd/pki/etcd.pem \
  --key-file=/opt/src/etcd/pki/etcd-key.pem \
  --client-cert-auth   --trusted-ca-file=/opt/src/etcd/pki/ca.pem \
  --peer-ca-file=/opt/src/etcd/pki/ca.pem \
  --peer-cert-file=/opt/src/etcd/pki/etcd.pem \
  --peer-key-file=${ETCD_KEY_FILE} \
  --peer-client-cert-auth \
  --peer-trusted-ca-file=${CA_FILE} \
  --log-output stdout

TimeoutSec=0
RestartSec=2
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
# 启动etcd服务
systemctl daemon-reload
systemctl restart etcd
systemctl enable etcd
systemctl status etcd
```
#### 5.3.4 查看etcd集群状态
```
# 创建软链接etcd命令
ln -s /opt/src/etcd/etcdctl /usr/local/sbin/

# 查看etcd集群健康检查
etcdctl cluster-health
member 407d22d9856f0b40 is healthy: got healthy result from http://127.0.0.1:2379
member 6d918c48ad5995f0 is healthy: got healthy result from http://127.0.0.1:2379
member c078f2e092d18dab is healthy: got healthy result from http://127.0.0.1:2379
cluster is healthy

# 查看etcd集群在线状态
etcdctl member list
407d22d9856f0b40: name=etcd-01 peerURLs=https://192.168.10.222:2380 clientURLs=http://127.0.0.1:2379,https://192.168.10.222:2379 isLeader=true
6d918c48ad5995f0: name=etcd-02 peerURLs=https://192.168.10.223:2380 clientURLs=http://127.0.0.1:2379,https://192.168.10.223:2379 isLeader=false
c078f2e092d18dab: name=etcd-03 peerURLs=https://192.168.10.224:2380 clientURLs=http://127.0.0.1:2379,https://192.168.10.224:2379 isLeader=false
```

## 6、安装Master节点组件

> Mater节点包括：kube-apiserver、kube-controller-manager、kube-scheduler和etcd

### 6.1 部署kube-apiserver
#### 6.1.1 下载kubernetes安装包
```
# 下载kubernetes二进制包
# wget -c -P /opt/src https://dl.k8s.io/v1.16.15/kubernetes-server-linux-amd64.tar.gz
# curl -L https://dl.k8s.io/v1.16.15/kubernetes-server-linux-amd64.tar.gz -o /opt/src/kubernetes-server-linux-amd64.tar.gz

curl -L https://dl.k8s.io/v1.18.8/kubernetes-server-linux-amd64.tar.gz -o /opt/src/kubernetes-server-linux-amd64.tar.gz

tar zxf /opt/src/kubernetes-server-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/kubernetes /opt/src/kubernetes-v1.18.8
ln -s /opt/src/kubernetes-v1.18.8 /opt/src/kubernetes
# 删除无用的镜像文件
rm -rf /opt/src/kubernetes/server/bin/*.tar
rm -rf /opt/src/kubernetes/server/bin/*_tag
```
#### 6.1.2 签发client证书
> 注意：apiserver在与etcd进行通信时，此时apiserver为客户端etcd为服务端，因此需要client证书加密通信。
>
> 🚨警告：修改`hosts`参数内ip地址
```
cat > /opt/kubernetes/pki/client-csr.json <<EOF
{
    "CN": "k8s-node",
    "hosts": [
        "192.168.10.221",
        "192.168.10.222",
        "192.168.10.223",
        "192.168.10.224",
        "192.168.10.225"
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
    ]
}
EOF
# 签发client证书
cd /opt/kubernetes/pki/
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json | cfssljson -bare client
```
#### 6.1.3 签发apiserver（server）证书
> 当其他客户端与apiserver进行通信时,也需要TLS认证，此时apiserver为服务端
>
> 🚨警告：修改`hosts`参数内ip地址
```
cat > /opt/kubernetes/pki/apiserver-csr.json <<EOF
{
    "CN": "apiserver",
    "hosts": [
        "127.0.0.1",
        "kubernetes.default",
        "kubernetes.default.svc",
        "kubernetes.default.svc.cluster",
        "kubernetes.default.svc.cluster.local",
        "192.168.10.221",
        "192.168.10.222",
        "192.168.10.223",
        "192.168.10.224",
        "192.168.10.225"
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
    ]
}
EOF
# 签发apiserver证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare apiserver
```
#### 6.1.4 配置apiserver日志审计
```
# 创建存放证书目录
mkdir -p /opt/src/kubernetes/server/bin/{pki,conf}
# 配置apiserver日志审计
cat > /opt/src/kubernetes/server/bin/conf/audit.yaml <<EOF
apiVersion: audit.k8s.io/v1 # This is required.
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
#### 6.1.5 拷贝apiserver相关证书
```
# 拷贝证书
mkdir -p /opt/src/kubernetes/server/bin/{pki,conf}
cp /opt/kubernetes/pki/ca.pem /opt/src/kubernetes/server/bin/pki/
cp /opt/kubernetes/pki/ca-key.pem /opt/src/kubernetes/server/bin/pki/
cp /opt/kubernetes/pki/client.pem /opt/src/kubernetes/server/bin/pki/
cp /opt/kubernetes/pki/client-key.pem /opt/src/kubernetes/server/bin/pki/
cp /opt/kubernetes/pki/apiserver.pem /opt/src/kubernetes/server/bin/pki/
cp /opt/kubernetes/pki/apiserver-key.pem /opt/src/kubernetes/server/bin/pki/
```

#### 6.1.6 创建TLSBootstrapping Token
> 🚨警告：修改`token.csv文件`内随机生成的token
```
head -c 16 /dev/urandom | od -An -t x | tr -d ' '
 
cat > /opt/src/kubernetes/server/bin/conf/token.csv <<EOF
3f0aac08a0a6d4070c02acd7141bbb1c,kubelet-bootstrap,10001,"system:node-bootstrapper"
EOF
```
> [可选项] 如使用supervisor启动apiserver服务,请点击跳转“使用supervisor启动apiserver”并忽略下方 “6.1.7 创建apiserver系统服务”

- 2、[使用supervisor启动apiserver](./supervisor.md)

#### 6.1.7 添加apiserver配置文件
> 🚨警告：修改`--service-cluster-ip-range`参数ip范围，此为集群中service的Ip范围
>
> 🚨警告：修改`--bind-address`绑定apiserver地址
> 
> 🚨警告：修改`--etcd-servers`参数etcd集群地址
```
mkdir -pv /etc/kubernetes/kube-apiserver/
cat > /etc/kubernetes/kube-apiserver/kube-apiserver.conf <<EOF
KUBE_APISERVER_OPTS="--apiserver-count 1 \\
  --v=2 \\
  --enable-admission-plugins NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \\
  --bind-address 192.168.10.222 \\
  --authorization-mode RBAC,Node \\
  --enable-bootstrap-token-auth true \\
  --token-auth-file /opt/src/kubernetes/server/bin/conf/token.csv \\
  --tls-cert-file /opt/src/kubernetes/server/bin/pki/apiserver.pem \\
  --tls-private-key-file /opt/src/kubernetes/server/bin/pki/apiserver-key.pem \\
  --requestheader-client-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --client-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --etcd-cafile /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --etcd-certfile /opt/src/kubernetes/server/bin/pki/client.pem \\
  --etcd-keyfile /opt/src/kubernetes/server/bin/pki/client-key.pem \\
  --etcd-servers https://192.168.10.222:2379,https://192.168.10.223:2379,https://192.168.10.224:2379 \\
  --service-cluster-ip-range 10.0.0.0/24 \\
  --service-node-port-range 3000-29999 \\
  --service-account-key-file /opt/src/kubernetes/server/bin/pki/ca-key.pem \\
  --target-ram-mb=1024 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path /data/kubernetes/logs/kube-apiserver/kube-apiserver.log \\
  --audit-policy-file /opt/src/kubernetes/server/bin/conf/audit.yaml \\
  --log-dir  /data/kubernetes/logs/kube-apiserver/ \\
  --kubelet-client-certificate /opt/src/kubernetes/server/bin/pki/client.pem \\
  --kubelet-client-key /opt/src/kubernetes/server/bin/pki/client-key.pem"
EOF
```
#### 6.1.8 创建apiserver系统服务
```
# vim /lib/systemd/system/kube-apiserver.service
cat > /lib/systemd/system/kube-apiserver.service <<\EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
EnvironmentFile=/etc/kubernetes/kube-apiserver/kube-apiserver.conf
ExecStart=/opt/src/kubernetes/server/bin/kube-apiserver $KUBE_APISERVER_OPTS
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```
#### 6.1.9 启动apiserver服务
```
systemctl daemon-reload
systemctl restart kube-apiserver
systemctl enable kube-apiserver
systemctl status kube-apiserver
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-apiserver.service
```

### 6.2 部署kube-controller-manager

- 3、[使用spuervisor启动kube-controller](./supervisor.md)

#### 6.2.1 添加controller配置文件
> 🚨警告：修改`--cluster-cidr`参数为kubernetes集群内pod地址网段
>
> 🚨警告：修改`--service-cluster-ip-range`参数,同apiserver配置一样
```
mkdir -pv /etc/kubernetes/kube-controller/
cat > /etc/kubernetes/kube-controller/kube-controller.conf <<EOF
KUBE_CONTROLLER_MANAGER_OPTS="--leader-elect true \\
  --address=127.0.0.1 \\
  --cluster-cidr 172.16.0.0/16 \\
  --master http://127.0.0.1:8080 \\
  --log-dir /data/kubernetes/logs/kube-controller-manager \\
  --service-cluster-ip-range 10.0.0.0/24 \\
  --service-account-private-key-file /opt/src/kubernetes/server/bin/pki/ca-key.pem \\
  --root-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --v 2"
EOF
```

#### 6.2.2 创建controller系统服务
```
# vim /lib/systemd/system/kube-controller.service
cat > /lib/systemd/system/kube-controller.service <<\EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/etc/kubernetes/kube-controller/kube-controller.conf
ExecStart=/opt/src/kubernetes/server/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
#### 6.2.3 启动controller系统服务
```
systemctl daemon-reload
systemctl restart kube-controller
systemctl enable kube-controller
systemctl status kube-controller
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-controller.service
```

### 6.3 部署kube-scheduler

- 4、[使用spuervisor启动kube-scheduler](./supervisor.md)

#### 6.3.1 添加kube-scheduler配置文件
```
mkdir -pv /etc/kubernetes/kube-scheduler/
cat > /etc/kubernetes/kube-scheduler/kube-scheduler.conf <<EOF
KUBE_SCHEDULER_OPTS="--logtostderr=false \\
--v=2 \\
--leader-elect \\
--master=127.0.0.1:8080 \\
--address=127.0.0.1 \\
--log-dir=/data/logs/kubernetes/kube-scheduler"
EOF
```
#### 6.3.2 创建kube-scheduler系统服务
```
# vim /lib/systemd/system/kube-scheduler.service
cat > /lib/systemd/system/kube-scheduler.service <<\EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=/etc/kubernetes/kube-scheduler/kube-scheduler.conf
ExecStart=/opt/src/kubernetes/server/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```
#### 6.3.3 启动kube-scheduler服务
```
systemctl daemon-reload
systemctl restart kube-scheduler
systemctl enable kube-scheduler
systemctl status kube-scheduler
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-scheduler.service
```
#### 6.3.4 创建kubectl软链接和检查集群状态
```
ln -s /opt/src/kubernetes/server/bin/kubectl /usr/local/sbin/
# 检查集群状态
kubectl get cs
kubectl get cs -o yaml
```


## 7、安装Node节点组件

> 注意：node节点上需要安装的组件为：kubelet、kubeproxy和docker
> 
> 🔥注意：下面操作需要在所有node节点上执行

### 7.1 部署kubelet
> 🔥注意：安装前需要先在CA节点给kubelet签发证书
> 
> 🔥注意：kubelet服务启动时需要docker环境否则无法启动
- [安装docker环境](../docs/docker.md)
- [拉取kubelet启动是所需镜像pause](#71-部署kubelet)
```
docker pull registry.cn-beijing.aliyuncs.com/zhoujun/pause:3.1
docker tag registry.cn-beijing.aliyuncs.com/zhoujun/pause:3.1 k8s.gcr.io/pause:3.1
docker rmi registry.cn-beijing.aliyuncs.com/zhoujun/pause:3.1
```

#### 7.1.1 下载node安装包
```
# 下载kubernetes-node
#curl -L https://dl.k8s.io/v1.16.15/kubernetes-node-linux-amd64.tar.gz -o /opt/src/kubernetes-node-linux-amd64.tar.gz
# 下载kubernetes-node v18.9
curl -L https://dl.k8s.io/v1.18.8/kubernetes-node-linux-amd64.tar.gz -o /opt/src/kubernetes-node-linux-amd64.tar.gz 

tar zxf /opt/src/kubernetes-node-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/kubernetes /opt/src/kubernetes-node-v1.18.8
ln -s /opt/src/kubernetes-node-v1.18.8/ /opt/src/kubernetes-node
# 创建目录
mkdir -p /opt/src/kubernetes-node/node/bin/{pki,conf}
```

#### 7.1.2 签发kubelet证书
> 🔥注意：在CA服务器给kubelet签发证书
- [在CA服务器上签发证书](#712-签发kubelet证书)
> 🚨警告：修改`hosts`参数内ip地址
```
cat > /opt/kubernetes/pki/kubelet-csr.json <<EOF
{
    "CN": "k8s-kubelet",
    "hosts": [
        "192.168.10.221",
        "192.168.10.222",
        "192.168.10.223",
        "192.168.10.224",
        "192.168.10.225"
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
    ]
}
EOF
# 签发kubelet证书
cd /opt/kubernetes/pki/
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server kubelet-csr.json | cfssljson -bare kubelet
```

#### 7.1.3 拷贝kubelet证书到node节点
- 从CA拷贝证书到各个node节点上证书目录下
```
# node01
scp /opt/kubernetes/pki/ca.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/client.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/client-key.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/kubelet.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/kubelet-key.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
# node02
scp /opt/kubernetes/pki/ca.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/client.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/client-key.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/kubelet.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/kubelet-key.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
```

```
# 创建kubelet命令软链接
ln -s /opt/src/kubernetes-node/node/bin/kubectl /usr/local/sbin/
```

#### 7.1.4 创建k8s-node.yaml配置

> 🔥注意：[此步在master节点执行](#714-创建kubelet配置)

```
cat > /opt/src/kubernetes/server/bin/conf/k8s-node.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: k8s-node
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:node
subjects:
- apiGroup: rbac.authorization.k8s.io
  kind: User
  name: k8s-node
EOF
# 创建配置
cd /opt/src/kubernetes/server/bin/conf/
kubectl create -f k8s-node.yaml
```

#### 7.1.5 创建kubelet.kubeconfig文件
> 🚨警告：修改`server`参数,API-Server地址
```
cat > /opt/src/kubernetes-node/node/bin/conf/kubelet.kubeconfig <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: 
    certificate-authority: /opt/src/kubernetes-node/node/bin/pki/ca.pem
    server: https://192.168.10.222:6443
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    namespace: default
    user: k8s-node
  name: default-context
current-context: default-context
kind: Config
preferences: {}
users:
- name: k8s-node
  user:
    client-certificate: /opt/src/kubernetes-node/node/bin/pki/client.pem
    client-key: /opt/src/kubernetes-node/node/bin/pki/client-key.pem
EOF
```
> [可选项] 如使用supervisor启动kubelet服务,请点击跳转“使用supervisor启动kubelet”并忽略下方7.1.6之后
- 5、[使用supervisor启动kubelet](./supervisor.md)
#### 7.1.6 添加kubelet配置文件
> 🚨警告：修改每个node节点上`--hostname-override`参数ip地址
```
mkdir -pv /etc/kubernetes/kubelet/
mkdir -pv /data/kubernetes/logs/kubelet
# 添加kubelet配置文件
cat > /etc/kubernetes/kubelet/kubelet.conf <<EOF
KUBELET_OPTS="--v=2 \\
  --anonymous-auth=false \\
  --cgroup-driver systemd \\
  --cluster-dns 192.168.0.2 \\
  --cluster-domain cluster.local \\
  --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice \\
  --fail-swap-on=false \\
  --client-ca-file /opt/src/kubernetes-node/node/bin/pki/ca.pem \\
  --tls-cert-file /opt/src/kubernetes-node/node/bin/pki/kubelet.pem \\
  --tls-private-key-file /opt/src/kubernetes-node/node/bin/pki/kubelet-key.pem \\
  --hostname-override k8s-node01 \\
  --image-gc-high-threshold 20 \\
  --image-gc-low-threshold 10 \\
  --kubeconfig /opt/src/kubernetes-node/node/bin/conf/kubelet.kubeconfig \\
  --log-dir /data/kubernetes/logs/kubelet \\
  --pod-infra-container-image k8s.gcr.io/pause:3.1 \\
  --root-dir /data/kubernetes/logs/kubelet"
EOF
```
#### 7.1.7 创建Kubelet系统服务
```
# vim /lib/systemd/system/kubelet.service
cat > /lib/systemd/system/kubelet.service <<\EOF
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Before=docker.service

[Service]
EnvironmentFile=/etc/kubernetes/kubelet/kubelet.conf
ExecStart=/opt/src/kubernetes-node/node/bin/kubelet $KUBELET_OPTS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```
#### 7.1.8 启动Kubelet系统服务
```
systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet
systemctl status kubelet
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kubelet
```

#### 7.1.7 查看node节点信息
```
# 检查所有节点并给节点打上标签
kubectl get node
NAME         STATUS   ROLES    AGE   VERSION
k8s-node01   Ready    <none>   53s   v1.18.8
k8s-node02   Ready    <none>   34s   v1.18.8
```
```
# 给节点打标签
kubectl label node k8s-node01 node-role.kubernetes.io/master=
kubectl label node k8s-node01 node-role.kubernetes.io/node=
```

### 7.2 部署kube-proxy
> 🔥注意：在CA服务器给kube-proxy签发证书

#### 7.2.1 签发kube-proxy证书
```
cat > /opt/kubernetes/pki/kube-proxy-csr.json <<EOF
{
    "CN": "system:kube-proxy",
    "hosts": [],
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
    ]
}
EOF
# 签发证书
cd /opt/kubernetes/pki/
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client kube-proxy-csr.json | cfssljson -bare kube-proxy
```
#### 7.2.2 拷贝kube-proxy证书到node节点
> 拷贝kube-proxy证书到node节点
```
# node01
scp /opt/kubernetes/pki/kube-proxy.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki
scp /opt/kubernetes/pki/kube-proxy-key.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki
# node02
scp /opt/kubernetes/pki/kube-proxy.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki
scp /opt/kubernetes/pki/kube-proxy-key.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki
```
#### 7.2.3 配置ipvs
```
# vim /root/ipvs.sh
cat > /root/ipvs.sh <<\EOF
#!/bin/bash 
ipvs_mods_dir="/usr/lib/modules/$(uname -r)/kernel/net/netfilter/ipvs"
for i in $(ls $ipvs_mods_dir|grep -o "^[^.]*")
do
  /sbin/modinfo -F filename $i &>/dev/null
  if [ $? -eq 0 ];then
    /sbin/modprobe $i
  fi
done
EOF
# 
chmod +x /root/ipvs.sh
sh /root/ipvs.sh
lsmod |grep ip_vs
yum -y install ipset ipvsadm

###或者（上下都可以开启ipvs）

cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
# 添加文件权限
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules
# 查看加载
lsmod | grep -e ip_vs -e nf_conntrack_ipv4
```
#### 7.2.4 创建kube-proxy.kubeconfig文件
> 🚨警告：修改`server`参数,API-Server地址
```
mkdir -pv /opt/src/kubernetes-node/node/bin/conf
cat > /opt/src/kubernetes-node/node/bin/conf/kube-proxy.kubeconfig <<EOF
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /opt/src/kubernetes-node/node/bin/pki/ca.pem
    server: https://192.168.10.222:6443
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    user: kube-proxy
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: kube-proxy
  user:
    client-certificate: /opt/src/kubernetes-node/node/bin/pki/kube-proxy.pem
    client-key: /opt/src/kubernetes-node/node/bin/pki/kube-proxy-key.pem
EOF
```
#### 7.2.5 创建kube-proxy配置文件
> 🚨警告：修改`--cluster-cidr`参数ip地址段,此ip段为pod的ip地址段
>
> 🚨警告：修改`--hostname-override`参数主机名
```
mkdir -pv /data/kubernetes/logs/kubeproxy/
cat > /etc/kubernetes/kube-proxy/kube-proxy.conf <<EOF
KUBE_PROXY_OPTS="--v=2 \\
  --cluster-cidr 172.16.0.0/16 \\
  --hostname-override k8s-node01 \\
  --proxy-mode=ipvs \\
  --ipvs-scheduler=nq \\
  --log-dir=/data/kubernetes/logs/kubeproxy \\
  --kubeconfig /opt/src/kubernetes-node/node/bin/conf/kube-proxy.kubeconfig"
EOF
```
#### 7.2.6 创建kube-proxy系统服务
```
cat > /lib/systemd/system/kube-proxy.service <<\EOF
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=/etc/kubernetes/kube-proxy/kube-proxy.conf
ExecStart=/opt/src/kubernetes-node/node/bin/kube-proxy $KUBE_PROXY_OPTS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
```
#### 7.2.7 启动kube-proxy系统服务
```
systemctl daemon-reload
systemctl restart kube-proxy
systemctl enable kube-proxy
systemctl status kube-proxy
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-proxy.service
```



