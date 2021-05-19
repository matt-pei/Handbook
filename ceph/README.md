# Ceph installation and deployment

### 设备主机名
```
hostnamectl set-hostname --static ceph-01 && bash
hostnamectl set-hostname --static ceph-02 && bash
hostnamectl set-hostname --static ceph-03 && bash
# 
cat >> /etc/hosts <<EOF

192.168.1.187  ceph-01
192.168.1.188  ceph-02
192.168.1.189  ceph-03
EOF
```

### ceph管理
```
# 设置ssh免密登陆
ssh-keygen -t rsa
拷贝到节点
ssh-copy-id -i .ssh/id_rsa.pub ceph-02
ssh-copy-id -i .ssh/id_rsa.pub ceph-03
# 或
for i in ceph-{02,03}; do ssh-copy-id -i .ssh/id_rsa.pub $i;done
```

### 所有节点
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
systemctl disable firewalld.service
systemctl stop firewalld.service
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

### 设置yum源
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

### 安装ceph-deploy
```
yum -y install ceph-deploy python-setuptools
```
### 创建ceph集群
```
# 创建ceph目录
mkdir -pv /etc/ceph-deploy && cd /etc/ceph-deploy
# aliyun环境设置内网段地址
ceph-deploy new --cluster-network 192.168.1.0/24 ceph-01
# ceph-deploy new ceph-01
# ceph-deploy new ceph-01 ceph-02 ceph-03
ceph-deploy install ceph-01 ceph-02 ceph-03
```

### 初始化monitor
初始化完后会生成keyring文件
```
ceph-deploy mon create-initial
```

### 拷贝认证密钥
`admin`是ceph-deploy的参数
```
ceph-deploy admin ceph-01 ceph-02 ceph-03
yum -y install ceph ceph-mgr ceph-mds ceph-mon ceph-radosgw
```

```
# 查看集群状态
ceph -s
# 创建mgr
ceph-deploy mgr create ceph-01
# 添加mon节点
ceph-deploy mon add ceph-02 --address 192.168.1.188
ceph-deploy mon add ceph-03 --address 192.168.1.189
# 查看mon状态
ceph mon stat
ceph mon dump
# 扩展mgr
ceph-deploy mgr create ceph-02 ceph-03
```

#### 清空磁盘
```
ceph-doploy disk zap ceph-01 /dev/sdb
```
### 创建osd
```
ceph-deploy osd create ceph-01 --data /dev/sdb
ceph-deploy osd create ceph-02 --data /dev/sdb
ceph-deploy osd create ceph-03 --data /dev/sdb
```

### 查看osd树
```
ceph osd tree
```

### 创建RBD资源池
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

### 映射镜像到本地
```
rbd map testrbd/test_images
# 
lsblk
# 查看磁盘映射信息
rbd showmapped
```





