#!/bin/bash
master="192.168.10.1"
node01="192.168.10.2"
node02="192.168.10.3"
node03="192.168.10.4"
node04="192.168.10.5"

# 设置 hostname 解析
echo "127.0.0.1   $(hostname)" >> /etc/hosts
# 设置集群主机名解析（ALL）
echo "192.168.10.228   k8s-main" >> /etc/hosts
echo "192.168.10.229   k8s-node01" >> /etc/hosts
echo "192.168.10.230   k8s-node02" >> /etc/hosts
# cfssl
echo "104.16.234.19   pkg.cfssl.org" >> /etc/hosts
echo "104.16.235.19   pkg.cfssl.org" >> /etc/hosts

# 关闭防火墙
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
# 关闭firewalld服务
systemctl stop firewalld.service
systemctl disable firewalld.service
# 关闭NetworkManager
systemctl stop NetworkManager
systemctl disable NetworkManager

# 安装常用工具
yum -y install vim wget net-tools htop pciutils epel-release tcpdump iptraf
yum -y install bash-completion chrony iotop sysstat bind-utils iptables-services
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

# ssh保持长链接
sed -i 's/^#ClientAliveInterval 0/ClientAliveInterval 30/' /etc/ssh/sshd_config
sed -i 's/^#ClientAliveCountMax 3/ClientAliveCountMax 86400/' /etc/ssh/sshd_config
systemctl restart sshd

# 自签CA颁发证书
mkdir -p /opt/kubernetes/pki
cd /opt/kubernetes/pki
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /usr/bin/cfssl-certinfo
# 添加执行权限
chmod +x /usr/bin/cfssl*
# 创建CA证书请求文件（csr）
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

# 创建基于根证书的config配置文件
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

# 部署etcd集群
cat > /opt/kubernetes/pki/etcd-peer-csr.json <<EOF
{
    "CN": "k8s-etcd",
    "hosts": [
        "${master}",
        "${node01}",
        "${node02}",
        "${node03}",
        "${node04}"
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

mkdir -p /opt/src/
curl -L https://mirrors.huaweicloud.com/etcd/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz
tar zxf /opt/src/etcd-v3.3.25-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/etcd-v3.3.25-linux-amd64 /opt/src/etcd-v3.3.25
# 为etcd做软链接,方便更新升级
ln -s /opt/src/etcd-v3.3.25 /opt/src/etcd
# 创建存放etcd证书目录
mkdir -p /opt/src/etcd/{pki,logs}
# master
cp /opt/kubernetes/pki/ca.pem /opt/src/etcd/pki/
cp /opt/kubernetes/pki/etcd.pem /opt/src/etcd/pki/
cp /opt/kubernetes/pki/etcd-key.pem /opt/src/etcd/pki/

# 添加etcd配置文件
mkdir -pv /etc/kubernetes/etcd/
mkdir -pv /data/kubernetes/etcd/data/
cat > /etc/kubernetes/etcd/etcd.conf <<EOF
#[Member]
ETCD_NAME="etcd-01"
ETCD_DATA_DIR="/data/kubernetes/etcd/data/"
ETCD_LISTEN_PEER_URLS="https://192.168.10.234:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.234:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.234:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.234:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://192.168.10.234:2380,etcd-02=https://192.168.10.235:2380,etcd-03=https://192.168.10.236:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

#[Certs]
CA_FILE="/opt/src/etcd/pki/ca.pem"
ETCD_CERT_FILE="/opt/src/etcd/pki/etcd.pem"
ETCD_KEY_FILE="/opt/src/etcd/pki/etcd-key.pem"
EOF

# 创建etcd系统服务
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
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u etcd
ln -s /opt/src/etcd/etcdctl /usr/local/sbin/




### 在node01、node02操作

mkdir -p /opt/src/
curl -L https://mirrors.huaweicloud.com/etcd/v3.3.25/etcd-v3.3.25-linux-amd64.tar.gz -o /opt/src/etcd-v3.3.25-linux-amd64.tar.gz
tar zxf /opt/src/etcd-v3.3.25-linux-amd64.tar.gz -C /opt/src/
mv /opt/src/etcd-v3.3.25-linux-amd64 /opt/src/etcd-v3.3.25
# 为etcd做软链接,方便更新升级
ln -s /opt/src/etcd-v3.3.25 /opt/src/etcd
# 创建存放etcd证书目录
mkdir -p /opt/src/etcd/{pki,logs}
# master
cp /opt/kubernetes/pki/ca.pem /opt/src/etcd/pki/
cp /opt/kubernetes/pki/etcd.pem /opt/src/etcd/pki/
cp /opt/kubernetes/pki/etcd-key.pem /opt/src/etcd/pki/

# 添加etcd配置文件
mkdir -pv /etc/kubernetes/etcd/
mkdir -pv /data/kubernetes/etcd/data/
cat > /etc/kubernetes/etcd/etcd.conf <<EOF
#[Member]
ETCD_NAME="etcd-02"
ETCD_DATA_DIR="/data/kubernetes/etcd/data/"
ETCD_LISTEN_PEER_URLS="https://192.168.10.235:2380"
ETCD_LISTEN_CLIENT_URLS="https://192.168.10.235:2379"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://192.168.10.235:2380"
ETCD_ADVERTISE_CLIENT_URLS="https://192.168.10.235:2379"
ETCD_INITIAL_CLUSTER="etcd-01=https://192.168.10.234:2380,etcd-02=https://192.168.10.235:2380,etcd-03=https://192.168.10.236:2380"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
ETCD_INITIAL_CLUSTER_STATE="new"

#[Certs]
CA_FILE="/opt/src/etcd/pki/ca.pem"
ETCD_CERT_FILE="/opt/src/etcd/pki/etcd.pem"
ETCD_KEY_FILE="/opt/src/etcd/pki/etcd-key.pem"
EOF

# 创建etcd系统服务
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
# 查看日志输出（没有报错就说明启动成功）
journalctl -f -u etcd
ln -s /opt/src/etcd/etcdctl /usr/local/sbin/

