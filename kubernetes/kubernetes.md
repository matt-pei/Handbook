# ⚙️ Deploy the Kubernetes cluster

<img alt="kubernetes logo" src="../images/logo.png" width="100">

---
## 🪂 二进制部署Kubernetes集群
## 1、节点规划
|    角色     |       IP       |                               组件                               |
| :---------: | :------------: | :--------------------------------------------------------------: |
| controlplan | 192.168.10.222 | kube-apiserver、kube-controller-manager、kube-scheduller、etcd01 |
| controlplan | 192.168.10.223 | kube-apiserver、kube-controller-manager、kube-scheduller、etcd02 |
| controlplan | 192.168.10.224 | kube-apiserver、kube-controller-manager、kube-scheduller、etcd03 |
|  k8s-node   |                |                        kube-proxy、docker                        |
|  k8s-node   |                |                        kube-proxy、docker                        |
|  k8s-node   |                |                        kube-proxy、docker                        |

## 2、系统初始化设置
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
192.168.10.222   controlplane
192.168.10.223   controlplane
192.168.10.224   controlplane
192.168.10.224   k8s-node
192.168.10.224   k8s-node
192.168.10.224   k8s-node
# cfssl
104.16.234.19   pkg.cfssl.org
104.16.235.19   pkg.cfssl.org
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
- 3、配置免密登陆
```
# master生成密钥
ssh-keygen -t rsa
for i in k8s-node{001,002};do ssh-copy-id -i ~/.ssh/id_rsa.pub $i;done
```
> ssh-keygen -t rsa -P ''
> 
> -P 表示空密码只需键入一次回车。无-P参数需键入三次回车

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
yum -y install vim wget iotop htop pciutils tcpdump sysstat epel-release
yum -y install chrony net-tools bash-completion iptables-services
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
```
# 配置登录超时自动退出
# echo "TMOUT=90000">> /root/.bashrc
echo "TMOUT=90000">> /root/.bash_profile
source .bash_profile
 
sed -i 's/^#ClientAliveInterval 0/ClientAliveInterval 30/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax 3/ClientAliveCountMax 86400/' /etc/ssh/sshd_config
systemctl restart sshd && reboot
```

## 3、自签CA颁发证书
### 3.1、安装cfssl工具
```
mkdir -pv /opt/kubernetes/pki
cd /opt/kubernetes/pki
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/bin/cfssl-certinfo
# 添加执行权限
chmod +x /usr/bin/cfssl*
```
### 3.2、生成CA证书
#### 3.2.1 创建CA config配置文件
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
#### 3.2.2 创建CA证书请求文件（csr）
```
cat > /opt/kubernetes/pki/ca-csr.json <<EOF
{
  "CN": "kubernetes",
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
       "O": "navinfo",
       "OU": "hdms"
     }
  ],
  "ca": {
     "expiry": "87600h"
  }
}
EOF
# 生成CA证书和私钥
cd /opt/kubernetes/pki/
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

## 4、部署etcd集群
### 4.1 创建etcd证书请求文件

```
cat > /opt/kubernetes/pki/etcd/etcd-peer-csr.json <<EOF
{
    "CN": "k8s-etcd",
    "hosts": [
        "10.130.36.18",
        "10.130.36.94",
        "10.130.36.120"
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
cd /opt/kubernetes/pki/etcd
cfssl gencert -ca=/opt/kubernetes/pki/ca.pem -ca-key=/opt/kubernetes/pki/ca-key.pem -config=/opt/kubernetes/pki/ca-config.json -profile=peer etcd-peer-csr.json | cfssljson -bare etcd
```

### 4.2 下载etcd安装包
> etcd采用集群模式(3台),分别在`master(etcd-01)` `node01(etcd-02)` `node02(etcd-03)`安装部署

```
mkdir -pv /opt/src/
curl -L https://github.com/etcd-io/etcd/releases/download/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz

tar zxf /opt/src/etcd-v3.3.25-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/etcd-v3.3.25-linux-amd64 /opt/src/etcd-v3.3.25
# 为etcd做软链接,方便更新升级
ln -s /opt/src/etcd-v3.3.25 /opt/src/etcd
# 创建存放etcd证书目录
mkdir -pv /etc/kubernetes/pki
```

```
# 华为源etcd

curl -L https://mirrors.huaweicloud.com/etcd/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz

curl -L https://mirrors.huaweicloud.com/etcd/v3.2.31/etcd-v3.2.31-linux-amd64.tar.gz -o /opt/src/etcd-v3.2.31-linux-amd64.tar.gz
```

### 4.3 配置etcd
#### 4.3.1 拷贝证书到node节点
```
# 3、拷贝证书
# master
yes|cp /opt/kubernetes/pki/{ca,etcd,etcd-key}.pem /etc/kubernetes/pki

# node01
scp /opt/kubernetes/pki/{ca,etcd,etcd-key}.pem k8s-node01:/etc/kubernetes/pki

# node02
scp /opt/kubernetes/pki/{ca,etcd,etcd-key}.pem k8s-node02:/etc/kubernetes/pki
```

#### 4.3.2 创建etcd配置文件
```
mkdir -pv /etc/kubernetes/etcd/
mkdir -pv /data/etcd/data/
# 下载官方配置文件

```
 
> [可选项] 如果想使用supervisor方式启动etcd和kubernetes组件服务,请点击跳转“使用spuervisor启动etcd”并忽略“4.3.3 创建etcd系统服务”
>  - 1、[使用spuervisor启动etcd](./supervisor.md)

#### 4.3.3 创建etcd系统服务
```
cat > /etc/systemd/system/etcd.service <<\EOF
[Unit]
Description=Etcd Server
Documentation=https://github.com/coreos
After=network.target
Wants=network-online.target

[Service]
Type=notify
ExecStart=/opt/src/etcd-v3.4.16/etcd --config-file=/etc/kubernetes/etcd/etcd.conf.yml

TimeoutSec=0
RestartSec=2
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
# 启动etcd服务
systemctl daemon-reload && systemctl enable etcd.service
systemctl start etcd.service
systemctl status etcd.service
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u etcd
```
#### 4.3.4 查看etcd集群状态
```
# 创建软链接etcd命令
ln -s /opt/src/etcd-v3.4.16/etcdctl /usr/local/sbin/

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

## 5、安装Master节点组件

> Mater节点包括：kube-apiserver、kube-controller-manager、kube-scheduler和etcd01

### 5.1 部署kube-apiserver
#### 5.1.1 下载kubernetes安装包
```
# 下载kubernetes二进制包
curl -L https://dl.k8s.io/v1.18.8/kubernetes-server-linux-amd64.tar.gz -o /opt/src/kubernetes-server-linux-amd64.tar.gz

tar zxf /opt/src/kubernetes-server-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/kubernetes /opt/src/kubernetes-v1.18.8
ln -s /opt/src/kubernetes-v1.18.8 /opt/src/kubernetes
# 删除无用的镜像文件
rm -rf /opt/src/kubernetes/server/bin/*.tar
rm -rf /opt/src/kubernetes/server/bin/*_tag
```
#### 5.1.2 签发client（apiserver）证书
> 注意：apiserver在与etcd进行通信时，此时apiserver为客户端etcd为服务端，因此需要client证书加密通信。
>
> 😡 注意：修改`hosts`参数内ip地址
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
# 签发client（apiserver）证书
cd /opt/kubernetes/pki/
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client-csr.json | cfssljson -bare client
```
#### 5.1.3 签发apiserver（server）证书
> 当其他客户端与apiserver进行通信时,也需要TLS认证，此时apiserver为服务端
>
> 😡 注意：修改`hosts`参数内ip地址
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
# 签发apiserver（server）证书
cd /opt/kubernetes/pki/
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server apiserver-csr.json | cfssljson -bare apiserver
```
#### 5.1.4 配置apiserver日志审计
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
#### 5.1.5 拷贝apiserver相关证书
```
# 拷贝证书
mkdir -pv /opt/src/kubernetes/server/bin/{pki,conf}
cp /opt/kubernetes/pki/{ca,ca-key,client,client-key}.pem /opt/src/kubernetes/server/bin/pki/
cp /opt/kubernetes/pki/{apiserver,apiserver-key}.pem /opt/src/kubernetes/server/bin/pki/
```

#### 5.1.6 创建TLSBootstrapping Token
> 😡 注意：修改`token.csv文件`内随机生成的token
```
mkdir -pv /etc/kubernetes/kube-apiserver/
head -c 16 /dev/urandom | od -An -t x | tr -d ' '
 
cat > /etc/kubernetes/kube-apiserver/token.csv <<EOF
3f0aac08a0a6d4070c02acd7141bbb1c,kubelet-bootstrap,10001,"system:node-bootstrapper"
EOF
```

#### 5.1.7 添加apiserver配置文件
```
mkdir -pv /etc/kubernetes/kube-apiserver/
cat > /etc/kubernetes/kube-apiserver/kube-apiserver.conf <<EOF
KUBE_APISERVER_OPTS="--apiserver-count 1 \\
  --v=2 \\
  --enable-admission-plugins NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \\
  --bind-address 192.168.10.222 \\
  --authorization-mode RBAC,Node \\
  --enable-bootstrap-token-auth true \\
  --token-auth-file /etc/kubernetes/kube-apiserver/token.csv \\
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
> 😡 注意：修改`--service-cluster-ip-range`参数ip范围，此为集群中service的Ip范围
>
> 😡 注意：修改`--bind-address`绑定apiserver地址
> 
> 😡 注意：修改`--etcd-servers`参数etcd集群地址
> 
> 🤔 [可选项] 如使用supervisor启动apiserver服务,请点击跳转“使用supervisor启动apiserver”并忽略 “5.1.8 创建apiserver系统服务”
>
> - 2、[使用supervisor启动apiserver](./supervisor.md)


#### 5.1.8 创建apiserver系统服务
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
#### 5.1.9 启动apiserver服务
```
systemctl daemon-reload
systemctl restart kube-apiserver
systemctl enable kube-apiserver
systemctl status kube-apiserver
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-apiserver.service
```

### 5.2 部署kube-controller-manager

#### 5.2.1 添加配置文件
```
mkdir -pv /etc/kubernetes/kube-controller/
cat > /etc/kubernetes/kube-controller/kube-controller.conf <<EOF
KUBE_CONTROLLER_MANAGER_OPTS="--leader-elect true \\
  --address=127.0.0.1 \\
  --allocate-node-cidrs=true \\
  --cluster-cidr 172.16.0.0/16 \\
  --master http://127.0.0.1:8080 \\
  --log-dir /data/kubernetes/logs/kube-controller-manager \\
  --service-cluster-ip-range 10.0.0.0/24 \\
  --service-account-private-key-file /opt/src/kubernetes/server/bin/pki/ca-key.pem \\
  --root-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --v 2"
EOF
```
> 😡 注意：修改`--cluster-cidr`参数为kubernetes集群内pod地址网段。
>
> 😡 注意：修改`--service-cluster-ip-range`参数,同apiserver配置一样
>
> 🤔 [可选项] 使用supervisor启动kube-controllerr服务，并忽略“5.2.2 创建controller系统服务”
> - 3、[使用spuervisor启动kube-controller](./supervisor.md)

#### 5.2.2 创建controller系统服务
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
#### 5.2.3 启动controller系统服务
```
systemctl daemon-reload
systemctl restart kube-controller
systemctl enable kube-controller
systemctl status kube-controller
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-controller.service
```

### 5.3 部署kube-scheduler

#### 5.3.1 添加kube-scheduler配置文件
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
> 🤔 [可选项] 使用supervisor启动kube-scheduler服务，并忽略“5.3.2 创建kube-scheduler系统服务”
> - 4、[使用spuervisor启动kube-scheduler](./supervisor.md)

#### 5.3.2 创建kube-scheduler系统服务
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
#### 5.3.3 启动kube-scheduler服务
```
systemctl daemon-reload
systemctl restart kube-scheduler
systemctl enable kube-scheduler
systemctl status kube-scheduler
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-scheduler.service
```
#### 5.3.4 创建kubectl软链接和检查集群状态
```
ln -s /opt/src/kubernetes/server/bin/kubectl /usr/local/sbin/
# 检查集群状态
kubectl get cs
kubectl get cs -o yaml
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


## 6、安装Node节点组件
### 6.1 部署kubelet
> 🤔 注意：node节点上需要安装的组件为：kubelet、kubeproxy和docker
> 
> 🔥 注意：下面操作需要在所有node节点上执行，安装前需要先在CA节点给kubelet签发证书
> 
> 🔥 注意：kubelet服务在启动时需要docker环境否则无法启动
- [安装docker环境](../docs/docker.md)
- [拉取kubelet启动是所需镜像pause](#71-部署kubelet)
```
docker pull registry.cn-beijing.aliyuncs.com/zhoujun/pause:3.1
docker tag registry.cn-beijing.aliyuncs.com/zhoujun/pause:3.1 k8s.gcr.io/pause:3.1
docker rmi registry.cn-beijing.aliyuncs.com/zhoujun/pause:3.1
```

#### 6.1.1 下载kubernetes-node安装包
```
# 下载kubernetes-node v18.9
curl -L https://dl.k8s.io/v1.18.8/kubernetes-node-linux-amd64.tar.gz -o /opt/src/kubernetes-node-linux-amd64.tar.gz 

mkdir -pv /opt/src/kubernetes-node-v1.18.8
tar zxf /opt/src/kubernetes-node-linux-amd64.tar.gz -C /opt/src/kubernetes-node-v1.18.8
mv /opt/src/kubernetes-node-v1.18.8/kubernetes/* /opt/src/kubernetes-node-v1.18.8/
ln -s /opt/src/kubernetes-node-v1.18.8/ /opt/src/kubernetes-node
# 创建目录
mkdir -p /opt/src/kubernetes-node/node/bin/{pki,conf}
```

#### 6.1.2 签发kubelet证书
> 😡 注意：在CA服务器给kubelet签发证书
> - [在CA服务器上签发证书](#612-签发kubelet证书)
> 
> 😡 注意：修改`hosts`参数内ip地址
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

#### 6.1.3 拷贝kubelet证书到node节点
- 从CA拷贝证书到各个node节点上证书目录下
```
# master
cp /opt/kubernetes/pki/{ca,client,client-key}.pem /opt/src/kubernetes-node/node/bin/pki/
cp /opt/kubernetes/pki/{kubelet,kubelet-key}.pem /opt/src/kubernetes-node/node/bin/pki/
# node01
scp /opt/kubernetes/pki/{ca.pem,client,client-key} k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/{kubelet,kubelet-key}.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki/
# node02
scp /opt/kubernetes/pki/{ca,client,client-key}.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
scp /opt/kubernetes/pki/{kubelet,kubelet-key}.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki/
```

```
# 创建kubelet命令软链接
ln -s /opt/src/kubernetes-node/node/bin/kubectl /usr/local/sbin/
```

#### 6.1.4 创建k8s-node.yaml配置

> 😡 注意：[此步在master节点执行](#714-创建kubelet配置)

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

#### 6.1.5 创建kubelet.kubeconfig文件
> 😡 警告：修改`server`参数,API-Server地址
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
#### 6.1.6 添加kubelet配置文件
```
mkdir -pv /etc/kubernetes/kubelet/
mkdir -pv /data/kubernetes/logs/kubelet
# 添加kubelet配置文件
cat > /etc/kubernetes/kubelet/kubelet.conf <<EOF
KUBELET_OPTS="--v=2 \\
  --anonymous-auth=false \\
  --cgroup-driver systemd \\
  --cluster-dns 10.0.0.1 \\
  --cluster-domain cluster.local \\
  --runtime-cgroups=/systemd/system.slice \\
  --kubelet-cgroups=/systemd/system.slice \\
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
> 😡 注意：修改每个node节点上`--hostname-override`参数ip地址
>
> 😡 注意：修改`--cluster-dns`为一个具体Ip,一定要对应apiserver`service-cluster-ip-range`和controller-manager`service-cluster-ip-range`等配置参数网段
> 
> 🤔 [可选项] 如使用supervisor启动kubelet服务,请点击跳转“使用supervisor启动kubelet”并忽略 "6.1.7 创建Kubelet系统服务"
> - 5、[使用supervisor启动kubelet](./supervisor.md)
#### 6.1.7 创建Kubelet系统服务
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
#### 6.1.8 启动Kubelet系统服务
```
systemctl daemon-reload
systemctl restart kubelet
systemctl enable kubelet
systemctl status kubelet
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kubelet
```

#### 6.1.7 查看node节点信息
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

### 6.2 部署kube-proxy
> 🔥注意：在CA服务器给kube-proxy签发证书

#### 6.2.1 签发kube-proxy证书
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
#### 6.2.2 拷贝kube-proxy证书到node节点
> 拷贝kube-proxy证书到node节点
```
# master
cp /opt/kubernetes/pki/{kube-proxy,kube-proxy-key}.pem /opt/src/kubernetes-node/node/bin/pki
# node01
scp /opt/kubernetes/pki/{kube-proxy,kube-proxy-key}.pem k8s-node01:/opt/src/kubernetes-node/node/bin/pki
# node02
scp /opt/kubernetes/pki/{kube-proxy,kube-proxy-key}.pem k8s-node02:/opt/src/kubernetes-node/node/bin/pki
```
#### 6.2.3 配置ipvs
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
#### 6.2.4 创建kube-proxy.kubeconfig文件
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
#### 6.2.5 创建kube-proxy配置文件

```
mkdir -pv /etc/kubernetes/kube-proxy
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
> 😡 注意：修改`--cluster-cidr`参数,此ip段为pod的ip地址网段.和controller`cluster-cidr`参数一致
>
> 😡 注意：修改`--hostname-override`参数主机名
#### 6.2.6 创建kube-proxy系统服务
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
#### 6.2.7 启动kube-proxy系统服务
```
systemctl daemon-reload
systemctl restart kube-proxy
systemctl enable kube-proxy
systemctl status kube-proxy
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u kube-proxy.service
```

