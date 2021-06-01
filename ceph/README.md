# Ceph installation and deployment

## 一、基础配置
### 1、设备主机名
```
hostnamectl set-hostname --static ceph001 && bash
hostnamectl set-hostname --static ceph002 && bash
hostnamectl set-hostname --static ceph003 && bash
# 
cat >> /etc/hosts <<EOF

192.168.1.187  ceph001
192.168.1.188  ceph002
192.168.1.189  ceph003
EOF
```

### 2、设置免密登录
```
# 设置ssh免密登陆
ssh-keygen -t rsa
拷贝到节点
ssh-copy-id -i .ssh/id_rsa.pub ceph-02
ssh-copy-id -i .ssh/id_rsa.pub ceph-03
# 或
for i in ceph{002,003}; do ssh-copy-id -i .ssh/id_rsa.pub $i;done
```

### 3、关闭防火墙
> 在所有节点执行
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld.service
systemctl stop firewalld.service
# 关闭NetworkManager
systemctl stop NetworkManager
systemctl disable NetworkManager
```

```
# 下载阿里epel源
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum -y install wget vim bash-completion chrony
#wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# 启动时间服务器
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
systemctl enable chronyd
systemctl start chronyd
# 立即手工同步
chronyc -a makestep
```

### 4、设置yum源
```
cat >> /etc/yum.repos.d/ceph.repo <<EOF
[ceph-noarch]
name=Ceph noarch packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/noarch/
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc

[ceph-x86_64]
name=Ceph x86_64 packages
baseurl=http://mirrors.aliyun.com/ceph/rpm-nautilus/el7/x86_64/
enabled=1
gpgcheck=0
type=rpm-md
gpgkey=https://download.ceph.com/keys/release.asc
EOF
```

## 二、安装
### 1、安装ceph-deploy
```
yum -y install ceph-deploy python-setuptools
```
### 2、创建ceph集群
```
# 创建ceph目录
mkdir -pv /etc/ceph-deploy && cd /etc/ceph-deploy
# aliyun环境设置内网段地址
ceph-deploy new --cluster-network 192.168.1.0/24 ceph001
# ceph-deploy new ceph-01 ceph-02 ceph-03

# yum安装方式要在所有节点执行
# ceph-deploy install ceph-01 ceph-02 ceph-03
yum -y install ceph ceph-mgr ceph-mds ceph-mon ceph-radosgw
```
### 3、初始化monitor
> 初始化完后会生成keyring文件
```
ceph-deploy mon create-initial
# 拷贝认证密钥
ceph-deploy admin ceph001 ceph002 ceph003
```
```
# 查看集群状态
ceph -s
# 创建mgr管理节点
ceph-deploy mgr create ceph001
# 扩展mon节点
ceph-deploy mon add ceph002 --address 192.168.1.188
ceph-deploy mon add ceph003 --address 192.168.1.189
# 查看mon状态
ceph mon stat
ceph mon dump
# 扩展mgr
ceph-deploy mgr create ceph002 ceph003
# 修改配置文件同步
ceph-deploy --overwrite-conf config push ceph001 ceph002 ceph003
```

## 三、块存储
### 1、创建osd块设备
```
ceph-deploy osd create ceph001 --data /dev/sdb
ceph-deploy osd create ceph002 --data /dev/sdb
ceph-deploy osd create ceph003 --data /dev/sdb
# 查看osd树
ceph osd tree
# 清空磁盘
ceph-doploy disk zap ceph-01 /dev/sdb
```

### 2、创建RBD资源池
> 通常在创建pool之前，需要覆盖默认的 pg_num，官方推荐：
>
>> 若少于5个OSD， 设置 pg_num 为128。
>
> > 5~10个OSD，设置 pg_num 为512。
>
>> 10~50个OSD，设置 pg_num 为4096。
>
>> 超过50个OSD，可以参考 pgcalc 计算。

```
ceph osd pool create testrbd 128
# 创建名为test_images的镜像
rbd create testrbd/test_images --image-feature layering --size 60G
# 查看镜像信息
rbd info testrbd/test_images
# 扩容镜像
rbd resize --size 600G testrbd/test_images
```
```
# 创建资源池
ceph osd pool create ceph-demo 64 64
# 查看osd资源池pg_num
ceph osd pool get ceph-demo pg_num
# 查看osd资源池pgp_num
ceph osd pool get ceph-demo pgp_num
# 查看osd资源池大小副本
ceph osd pool get ceph-demo size
# osd资源池调度算法
ceph osd pool get ceph-demo crush_rule
# 设置资源池副本大小
ceph osd pool set ceph-demo size 2
# 设置资源池pg数量
ceph osd pool set ceph-demo pg_num 128
ceph osd pool set ceph-demo pgp_num 128
```
### 3、创建镜像
```
# 从资源池创建镜像
rbd create -p ceph-demo --image rbd-demo.img --size 10G
rbd create ceph-demo/rbd-demo-1.img --size 10G
# 查看镜像信息
rbd -p ceph-demo info rbd-demo.img
# 禁用镜像特性
rbd feature disable ceph-demo/rbd-demo.img xxxx
# 挂着镜像到本地
rbd map ceph-demo/rbd-demo.img
# 查看磁盘映射信息
rbd showmapped
rbd devide list
# 镜像扩容
rbd resize ceph-demo/rbd-demo.img --size 20G
# 文件系统扩容
xfs_growfs /dev/rbd0
```
```
# 查看数据流
rados -p ceph-demo ls | grep rbd_data.10d26aaaf109
# 查看每个object大小
rados -p ceph-demo stat rbd_data.10d26aaaf109.00000000000001e0
# 查看object所在pg
ceph osd map ceph-demo rbd_data.10d26aaaf109.0000000000000960
```
### 4、集群健康状态
```
# 查看集群将康状态
ceph health detail
# 资源池分类
ceph osd pool application enable ceph-demo rbd
# 查看应用
ceph osd pool application get ceph-demo
# 查看告警信息
ceph crash ls
# 查看告警具体信息
ceph crash info xxxxxx
```

### yum查看命令所在安装包
yum whatprovides "*bin/netstat"

## 四、对象存储

```
aws s3 ls s3://xxxx
aws s3 cp xxx s3://xxxx
# 安装rgw对象网关
ceph-deploy rgw create ceph001 
# 测试访问
crul http://ceph001:7480
# 修改rgw默认端口
vim /etc/ceph-deploy/ceph.conf
[client.rgw.ceph001]
rgw_frontends = "civetweb port=80"
# 覆盖节点配置
ceph-deploy --overwrite-conf config push ceph001 xxxx xxxx
# 重启rgs服务
systemctl restart ceph-radosgw.target
# 创建用户
radosgw-admin create --uid ceph-s3-demo --displsy-name "Ceph S3 User Demo"
# 查看用户信息
radosgw-admin user info --uid ceph-s3-demo
```
```
# 使用工具
yum -y install s3cmd
# 创建swift用户
radosgw-admin subuser create --uid ceph-s3-demo --subuser=testuser:swift --access=full
# 生成key
radosge-admin key create --subuser=ceph-s3-demo:swift --key-type=swift --gen-ecret
```

## 五、文件存储

```
# 安装mds
ceph-deploy mds create ceph001 ceph002 ceph003
# 查看mds
ceph mds stat
ceph mds dump
# 创建资源池--元数据
ceph osd pool create cephfs_metadata 16 16
# 创建资源池--数据
ceph osd pool create cephfs_data 16 16
# 创建文件系统
ceph fs new cephfs-demo cephfs_metadata cephfs_data
ceph fs ls
```
### 内核挂载
```
# 挂载cephfs
mount -t ceph Ip:port:/  /path/
```

### 用户态挂载
```
# 安装客户端
yum -y install ceph-fuse
# 挂载
ceph-fuse -n client.admin -m ip:port,ip:port,ip:port /path/
```


