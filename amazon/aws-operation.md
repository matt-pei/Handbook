> 

## 一、AWS服务

#### 1、EKS配置连接

1. 安装kubectl管理eks集群    [aws参考文档](https://docs.amazonaws.cn/en_us/eks/latest/userguide/install-kubectl.html)
```shell
# 下载aws提供kubectl
curl -o kubectl https://s3.cn-north-1.amazonaws.com.cn/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl
```

2. 下载校验
- 下载校验文件
```shell
# 下载SHA-256校验文件
curl -o kubectl.sha256 https://s3.cn-north-1.amazonaws.com.cn/amazon-eks/1.22.6/2022-03-09/bin/linux/amd64/kubectl.sha256
```

- 验证校验总和
```shell
# 验证二进制文件SHA-256 总和
openssl sha1 -sha256 kubectl
```

3. 添加执行权限
```shell
# 添加执行权限
chmod +x ./kubectl
# 移动/bin/目录
mv kubectl /bin/	# aws ec2机器执行此操作
```

4. 配置kubeconfig文件   [aws参考文档](https://docs.amazonaws.cn/eks/latest/userguide/create-kubeconfig.html)
```shell
# 创建kubeconfig文件
aws eks update-kubeconfig --region xxxx --name cluster-name
```
#### 2、ECR配置连接

1. 配置docker
```shell
# ECR验证docker
aws ecr get-login-password --region cn-northwest-1 | docker login --username AWS --password-stdin 388144527693.dkr.ecr.cn-northwest-1.amazonaws.com.cn
```

2. 更改tag
```shell
# 更改tag
docker tag hdms/id-log:xxxx 388144527693.dkr.ecr.cn-northwest-1.amazonaws.com.cn/hdms/id-log:latest
# 推送到ECR
docker push 388144527693.dkr.ecr.cn-northwest-1.amazonaws.com.cn/hdms/id-log:latest
```
#### 3、AWS CLI安装

1. 下载安装文件     [aws参考文档](https://docs.amazonaws.cn/cli/latest/userguide/getting-started-install.html)
```shell
# 下载安装包文件
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
```

2. 解压缩
```shell
# 解压文件
unzip awscliv2.zip
```

3. 安装aws  cli
```shell
# 安装运行
sudo ./aws/install
# 查找链接文件
which aws
# 确认安装
aws --version
```
4. 升级aws cli
```shell
# 升级aws cli命令
## 默认安装为1版本
~]# ./aws/install --bin-dir /usr/bin --install-dir /usr/aws-cli --update
You can now run: /usr/bin/aws --version
~]# aws --version
aws-cli/2.7.18 Python/3.9.11 Linux/5.10.118-111.515.amzn2.x86_64 exe/x86_64.amzn.2 prompt/off
```

5. 配置aws cli认证   [aws参考文档](https://docs.amazonaws.cn/cli/latest/userguide/cli-configure-files.html)
```shell
~]# aws configure
AWS Access Key ID [None]: AKIA***********SAQU5
AWS Secret Access Key [None]: n74JbaUb*******************pQ10Qj93JeeTI
Default region name [None]: cn-northwest-1
Default output format [None]:
```
```shell
# AWS命令操作
aws s3 cp xxx s3://xxxxxxxxxxx/xxxx/	# 上传文件
aws s3 sync ./ s3://xxxxxxxxxx/ --include "*.gz"	# 上传目录

# 创建s3存储桶
aws s3 mb s3://data-backup-bucket
aws s3api create-bucket --bucket data-backup-bucket --acl private --region cn-northwest-1 --create-bucket-configuration LocationConstraint=cn-northwest-1
# 删除存储桶
aws s3 rb s3://xxxxxxx
aws s3 rb s3://xxxxxxx --force
aws s3api delete-bucket --bucket xxxxxxxxxxxxxxxxxx --region cn-northwest-1

aws s3 ls
aws s3 ls s3://xxxxx

```
#### 4、EFS配置安装

1. 安装efs   [参考文档](https://docs.amazonaws.cn/efs/latest/ug/installing-amazon-efs-utils.html)
```shell
# amazon-efs-utils软件包
yum install -y amazon-efs-utils

```

2. 配置自动挂载
```shell
# 编辑自动挂载
vim /etc/fstab
fs-06a2da36b9944ada3:/  /efs    efs _netdev,noresvport   0 0
# 挂载efs
mount -a
# 查看挂载
df -Th
```
#### 5、EC2服务配置

1. 格式化磁盘
```shell
# 磁盘分区
parted /dev/nvme1n1
mklabel
gpt
mkpart
primary
ext4
1
100G
# 格式化磁盘
mkfs.xfs -f -n ftype=1 /dev/nvme1n1
mkdir -pv /data
# 查看磁盘uuid
blkid
vim /etc/fstab
UUID=97dc2317-xxxx-xxxx-xxxx-5fd4d53793d2 /data xfs defaults 0 0
mount -a && df -Th
```
```
# 配置更新yum源
mkdir -pv /etc/yum.repos.d/backup
mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/
```

2. 配置时间服务
```shell
# 安装所需工具
yum -y install htop bash-completion
# 调整时间服务器
# chrony 默认安装
cp /etc/chrony.conf /etc/chrony.conf_$(date +%Y%m%dT%H%M%S)
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
# 更改时区
yes | cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```

3. 安装docker
```shell
# 创建目录
mkdir -pv /data/docker_storage
# 列出所有 Docker 可用的版本
yum list docker --showduplicates
# 部署指定版本的 Docker
yum -y install docker-19.03.13ce-1.amzn2 
# amazon-linux-extras install docker -y
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "data-root": "/data/docker_storage",
  "debug": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ],
  "insecure-registries" : ["xxxxxx"],
  "registry-mirrors": ["https://g427vmjy.mirror.aliyuncs.com"],
  "live-restore": true
}
EOF
systemctl daemon-reload && systemctl enable docker --now
systemctl start docker
systemctl status docker
```

4. 阿道夫




## 二、Elastic
### 1、备份数据
#### 1、创建仓库
```shell
# 创建仓库目录
mkdir -pv /efs/elastic/
# 创建仓库
curl -H "Content-Type: application/json" -XPUT http://10.9.4.86:9200/_snapshot/com_navinfo_2022-07-29 -d '
{
    "type": "fs",
    "settings": {
        "location": "/efs/elastic/com_navinfo_2022-07-29",
        "max_snapshot_bytes_per_sec": "1024mb",
        "max_restore_bytes_per_sec": "1024mb"
    }
}'

#2019-03-08 共享仓库名称
#“type”:”fs”    指定仓库类型是一个共享文件系统
#“location”: “/data/backup” 指定挂载目录
#“max_snapshot_bytes_per_sec" : "50mb"  控制快照存到仓库时的限流情况，默认每秒20mb
#"max_restore_bytes_per_sec" : "50mb"   控制从仓库恢复数据时的限流情况，默认每秒20mb
```
#### 2、更改配置
```shell
# 更改仓库配置（跳过）
curl -H "Content-Type: application/json" -XPOST http://10.9.4.86:9200/_snapshot/com_navinfo_2022-07-27 -d '
{
    "type": "fs",
    "settings": {
        "location": "/efs/elastic/com_navinfo_2022-07-27",
        "max_snapshot_bytes_per_sec": "200mb",
        "max_restore_bytes_per_sec": "200mb"
    }
}'
```
#### 3、备份指定索引
```shell
# 备份索引
curl -H "Content-Type: application/json" -XPUT http://10.9.4.86:9200/_snapshot/com_navinfo_2022-07-29/com.navinfo.imp.id_2022-07-29?wait_for_completion=true -d '
{
    "indices": "com.navinfo.imp.id_2022-07-29"
}'
# com.navinfo.imp.id_2022-07-29  快照名称
# wait_for_completion    默认快照时会进入后台执行，添加该标记可以阻止进入后台执行，常在脚本中使用。
# "indices"  指定要做快照的索引
```
#### 4、备份多个索引
```shell
#
curl -H "Content-Type: application/json" -XPUT http://10.9.4.86:9200/_snapshot/仓库名/备份快照名?wait_for_completion=true -d '
{
    "indices": "xxxxx1,xxxxx2,xxxxx3,xxxxx4,xxxxx5"
}'
```
```shell
# 全量备份
curl -XPUT "http://10.9.4.86:9200/_snapshot/仓库名/snapshot_1?wait_for_completion=true"
```

### 2、恢复数据
#### 1、全量恢复 
```shell
#
curl -X POST "10.9.4.86:9200/_snapshot/仓库名/备份快照名/_restore"
```
```shell
# 恢复指定索引
curl -X POST "http://10.9.4.86:9200/_snapshot/仓库名/备份快照名/_restore" -H 'Content-Type: application/json' -d'
{
  "indices": "index_1,index_2",
  "ignore_unavailable": true,
  "include_global_state": true,
  "rename_pattern": "index_(.+)",
  "rename_replacement": "restored_index_$1"
}'
# 恢复指定索引
curl -X POST "http://10.9.4.86:9200/_snapshot/仓库名/备份快照名/_restore" -H 'Content-Type: application/json' -d'
{
  "indices": "com.navinfo.imp.id_2022-07-26"
}'

# indices, 表示只恢复索引’index_1’
# rename pattern: 表示重命名索引以’index ‘开头的索引
# rename_replacement: 表示将所有的索引重命名为’restored_index_xxx’.如index_1会被重命名为restored_index_1.
```

### 3、ES命令操作
#### 1、常用命令
```shell
# 查看node节点
curl -XGET 'http://10.9.4.86:9200/_cat/nodes?v'
# 查看es状态
curl http://`hostname -I | awk '{print $1}'`:9200/_cat/health?v
curl -XGET 'http://10.9.4.86:9200/_cluster/health?pretty'
# 查看es分片信息
curl http://10.9.4.86:9200/_cat/shards?v
# 查看es指定索引分片
curl http://10.9.4.86:9200/_cat/shards/xxx?v
# 查询es索引
curl -XGET 'http://10.9.4.86:9200/_cat/indices?v'
curl -XGET 'http://10.9.4.86:9200/_cat/indices/xxxx?v'
# 删除索引
curl -X DELETE '10.9.4.86:9200/索引名'

# 批量删除索引
for i in `curl -X GET '10.201.7.56:9200/_cat/indices' | awk '{print $3}'`;
do
curl -X DELETE '10.201.7.56:9200/$i';
done


# 列出存储库
curl -XGET 10.9.4.86:9200/_snapshot/_all?pretty
# 删除存储库
curl -XDELETE http://10.9.4.86:9200/_snapshot/仓库名
# 列出快照
curl -XGET http://127.0.0.1:9200/_snapshot/仓库名/*
# 删除快照
curl -XDELETE http://127.0.0.1:9200/_snapshot/仓库名/快照名
# 查看备份状态
curl -XGET http://10.9.4.86:9200/_snapshot/仓库名/备份快照名/_status
```
#### 2、排查分片
```shell
# 查看状态为UNASSIGNED的分片
curl -XGET "http://10.201.7.56:9200/_cat/shards?h=index,shard,prirep,state,unassigned.reason" | grep "UNASSIGNED"
# 查看Unassigned的原因
curl -XGET "http://10.201.7.56:9200/_cluster/allocation/explain?pretty"

```
### 4、ES备份到S3
#### 1、修改jvm配置参数
```shell
# es配置文件下jvm.options文件
# 修改jvm.options配置文件添加参数
-Des.allow_insecure_settings=true
```
#### 2、安装插件
```shell
# 安装S3 Repository Plugin插件
path/elasticsearch-plugin install repository-s3
```
#### 3、配置s3密钥
```shell
# 配置s3密钥AKSK
/path/bin/elasticsearch-keystore add s3.client.default.access_key
    AKIAXXXXXXXXXXMQSAQU5
/path/bin/elasticsearch-keystore add s3.client.default.secret_key
    n74JbaUXXXXXXXXXXXXXXXXXXXXXXXXXj93JeeTI
# 重启ES服务
```
#### 4、创建备份仓库

> 需提前在s3存储桶创建目录
>
> 创建s3存储桶
> 
> aws s3api put-object --bucket data-backup-hdms-cn-northwest --key hdms_nginxlog/September/hdms_nginxlog-202209/

```shell
curl -H "Content-Type: application/json" -XPUT 'http://10.9.4.86:9200/_snapshot/仓库名' -d '
{
    "type": "s3",
    "settings": {
        "bucket": "data-backup-hdms-cn-northwest",
        "region": "cn-northwest-1",
        "base_path": "hdms_cacenter_test/hdms_cacenter_test-202209",
        "max_snapshot_bytes_per_sec": "4096mb",
        "max_restore_bytes_per_sec": "4096mb",
        "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
    }
}'

region：指定s3可用区，必须
base_path：指定s3存储桶一个目录，否则会存放存储桶/根目录下。
endpoint： 指定s3中国区的endpoint，其他区咨询AWS。必须
max_restore_bytes_per_sec: 每个节点的最大快照还原率。默认为无限制
max_snapshot_bytes_per_sec: 每个节点的最大快照创建率。默认为40mb每秒
```
#### 5、备份索引到s3
```shell
# 
curl -H "Content-Type: application/json" -XPUT http://10.9.4.86:9200/_snapshot/仓库名/备份索引名?wait_for_completion=true -d '
{
    "indices": "hdms_nginxlog_2022-08-31"
}'
```


## 三、RKE部署
### 1、安装RKE
#### 1、下载可执行程序
> RKE版本对应安装kubernetes版本    [参考地址](https://github.com/rancher/rke/releases)

```shell
# 下载RKE
wget -c https://github.com/rancher/rke/releases/download/v1.3.11/rke_linux-amd64
```
#### 2、添加可执行权限
```shell
# 添加权限改名
chmod +x rke_linux-amd64
mv rke_linux-amd64 rke

```







## Redis服务
### 1、连接Redis服务
> **1、HDMS 项目**

```shell
一、连接Redis服务
1、预生产化境
# 10.201.32.24
/data/aws-redis/redis-stable/src/redis-cli -h pre-ec-rd-id.rwzege.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379

2、生产环境
# ssh -i pro-key-pair-private.pem 10.201.4.229
/data/aws-redis/redis-stable/src/redis-cli -h pro-ec-rd-id.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379

```
> **2、DSG项目**

```shell
一、连接Redis服务
1、生产环境
# ssh -i pro-key-pair-private.pem 10.203.232.11
/opt/redis-5.0.13/src/redis-cli -h pro-dsg-redis-ro.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379
```
#### 
### **2、Redis操作数据**
```shell
一、Redis数据
1、导出Redis所有的key
/opt/redis-5.0.13/src/redis-cli --raw -h pro-ec-rd-id-ro.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 --scan >> ./redis_ecrd_all_key.csv

2、查看Redis最大的key
/opt/redis-5.0.13/src/redis-cli -h pro-dsg-redis-ro.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 --scan --bigkeys

```

---

```shell
一、删除Redis key
1、预生产环境
# ssh -i cn-nx-pre-key-pair-protect.pem 10.201.33.56
/opt/src/redis-5.0.13/src/redis-cli -h pre-ec-rd-id.rwzege.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 KEYS oso:xxxx* | xargs -r -t -n1 /opt/src/redis-5.0.13/src/redis-cli -h pre-ec-rd-id.rwzege.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 DEL

2、生产环境
# 4.229
/data/aws-redis/redis-stable/src/redis-cli -h pro-ec-rd-id.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 keys oso:xxxx* | xargs /data/aws-redis/redis-stable/src/redis-cli -h pro-ec-rd-id.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 del

```


## 二、Postgres服务
### 1、清空表数据
```shell
1、清空表中的数据（非表字段）
delete from daimler02.hcc_attributes;
```

#### 2、安装pgaddmin
```shell
# 安装pgadmin
docker run -dit --name pgadmin --restart always -p 5050:80 -e 'PGADMIN_DEFAULT_EMAIL=admin@pgadmin.com' -e 'PGADMIN_DEFAULT_PASSWORD=navinfo@9099' -e 'PGADMIN_CONFIG_ENHANCED_COOKIE_PROTECTION=True' -e 'PGADMIN_CONFIG_LOGIN_BANNER="Authorised users only!"' -e 'PGADMIN_CONFIG_CONSOLE_LOG_LEVEL=10' -v /data/pgadmin_data/:/var/lib/postgresql/data dpage/pgadmin4:5.0
```


> 需手动在dcos服务中更改对应的镜像tag即可。

```shell
# 安装部署监控
# node_exporter
docker run -d --net="host" --name node_exporter -p 9100:9100 --pid="host" -v "/:/host:ro,rslave" prom/node-exporter:v1.3.1 --path.rootfs=/host
# prometheus
docker run -dit --restart always --name prometheus -p 9090:9090 -v /data/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml --network host prom/prometheus:v2.34.0
# cadvisor
docker run -dit --restart always --volume=/:/rootfs:ro --volume=/var/run:/var/run:ro --volume=/sys:/sys:ro --volume=/data/docker_storage/:/var/lib/docker:ro --volume=/dev/disk/:/dev/disk:ro --publish=8080:8080 --detach=true --name=cadvisor --privileged --device=/dev/kmsg google/cadvisor:v0.33.0
# grafana
chmod -R 777 /data/grafana/grafana-storage/
docker run -dit --restart always --name grafana -p 3000:3000 -v /data/grafana/grafana-storage/:/var/lib/grafana -v /data/grafana/defaults.ini:/usr/share/grafana/conf/defaults.ini grafana/grafana:8.4.0

```
### 
