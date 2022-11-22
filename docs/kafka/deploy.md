> a

## 一 、Kafka服务
### 一、部署zookeeper集群
#### 1、准备jdk环境
```shell
tar zxf /tmp/jdk-8u202-linux-x64.tar.gz -C /usr/local/jdk
vim /etc/profile
export JAVA_HOME=/usr/local/jdk1.8.0_202/
export PATH=$PATH:$JAVA_HOME/bin
```
| 服务类型 | IP | 需要组件 |
| --- | --- | --- |
| zookeeper-01 | 10.201.34.130 | jdk |
| zookeeper-02 | 10.201.34.171 | jdk |
| zookeeper-03 | 10.201.34.198 | jdk |

#### 2、关闭防火墙
```shell
# 关闭selinux
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
# 关闭firewalld服务
systemctl stop firewalld.service
systemctl disable firewalld.service
```
#### 3、安装zookeeper
```shell
# 创建安装目录
mkdir -pv /opt/src
# 下载zookeeper
wget -c -P /opt/src https://dlcdn.apache.org/zookeeper/zookeeper-3.5.9/apache-zookeeper-3.5.9-bin.tar.gz
# 解压缩并改名
tar zxf /opt/src/apache-zookeeper-3.5.9-bin.tar.gz -C /data/
mv /data/apache-zookeeper-3.5.9-bin/ /data/zookeeper-3.5.9
cp /data/zookeeper-3.5.9/conf/zoo_sample.cfg /data/zookeeper-3.5.9/conf/zoo.cfg
```

1. 修改配置文件
```shell
# 配置zookeeper集群
vim /data/zookeeper-3.5.9/conf/zoo.cfg
  tickTime=2000	初始同步的毫秒数
  initLimit=10
  syncLimit=5
  dataDir=/data/zookeeper-3.5.9/data
  clientPort=2181
```

2. 创建集群
```shell
# 添加
vim /data/zookeeper-3.5.9/conf/zoo.cfg
  server.1=zk-01:2888:3888
  server.2=zk-02:2888:3888
  server.3=zk-03:2888:3888
```
:::info
server.A=B:C:D
- A 是一个数字表示是第几个服务。集群模式下需要在zoo.cfg中dataDir指定的目录下创建一个文件myid文件里面有一个数据就是A的值，zookeeper启动时读取此文件，拿到里面的数据与zoo.cfg里面的配置信息比较从而判断到底是哪个server。
- B 是这个服务器的地址。
- C 是这个服务器Follower与集群中的Leader服务器交换信息的端口。
- D 是万一集群中的Leader服务器挂了，需要一个端口来重新进行选举，选出一个新的Leader，而这个端口就是用来执行选举时服务器相互通信
:::

3. 创建myid文件
```shell
mkdir -pv /data/zookeeper-3.5.9/data
# 每个zk节点执行
echo 1 > /data/zookeeper-3.5.9/data/myid
echo 2 > /data/zookeeper-3.5.9/data/myid
echo 3 > /data/zookeeper-3.5.9/data/myid
```
#### 4、启动服务
```shell
/data/zookeeper-3.5.9/bin/zkServer.sh start
```
```shell
vim /opt/src/zookeeper
#!/bin/bash
ZK_HOME='/data/zookeeper-3.5.9/'

case $1 in
start)
$ZK_HOME/bin/zkServer.sh start
;;
stop)
$ZK_HOME/bin/zkServer.sh stop
;;
restart)
$ZK_HOME/bin/zkServer.sh restart
;;
status)
$ZK_HOME/bin/zkServer.sh status
;;
*)
echo "Usage: /data/zookeeper-3.5.9/bin/zkServer.sh [--config <conf-dir>] {start|start-foreground|stop|restart|status|print-cmd}"
  ;;
esac
```

### 二、部署kafka服务

#### 1、下载并解压
```shell
# 下载Kafka
wget -c -P /opt/src https://archive.apache.org/dist/kafka/2.8.1/kafka_2.12-2.8.1.tgz

tar zxf /opt/src/kafka_2.12-2.8.1.tgz -C /usr/local/
ln -s /usr/local/kafka_2.12-2.8.1/ /data/kafka
```

#### 2、配置Kafka

1. 修改配置文件
```shell
# node 1节点
vim /data/kafka/config/server.properties
  broker.id=1
  listeners=INTERNAL://10.201.34.130:9092,EXTERNAL://10.201.34.130:19093
  advertised.listeners=INTERNAL://10.201.34.130:9092,EXTERNAL://hdmap-cn-pre-l4.navinfo.com:19093
  listener.security.protocol.map=INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
  inter.broker.listener.name=INTERNAL
  log.dirs=/data/kafka/logs
  zookeeper.connect=xx.xx.xx.xx:2181,xx.xx.xx.xx:2181,xx.xx.xx.xx:2181
# node 2节点

# node 3节点
```

2. 配置安全认证
```shell
# 创建日志目录
mkdir -pv /data/kafka/logs

vim /data/kafka/config/kafka_client_jaas_adminstrator.conf
  KafkaClient {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="adminstrator"
    password="adminstrator";
  };

vim /data/kafka/config/kafka_server_jaas.conf
  KafkaServer {
    org.apache.kafka.common.security.scram.ScramLoginModule required
    username="admin"
    password="admin";
  };
```

3. 配置Kafka环境变量
```shell
# 配置Kafka环境变量
cat >> /etc/profile <<EOF

# kafka
export KAFKA_HOME=/usr/local/kafka
export PATH=$PATH:$KAFKA_HOME/bin
EOF

source /etc/profile
```
#### 3、启动Kafka服务
```shell
/data/kafka/bin/kafka-server-start.sh /data/kafka/config/server.properties  &
```





```shell
# kafka创建用户到zk
./kafka-configs.sh --zookeeper 10.201.40.171:2181/kafka/public-kafka --alter --add-config 'SCRAM-SHA-256=[password=erTePBeXcrGVC7pdP52zMXOX],SCRAM-SHA-512=[password=erTePBeXcrGVC7pdP52zMXOX]' --entity-type users --entity-name admin

# 查看topic
kafka-topics.sh --list --zookeeper  10.131.11.243:2181
# 查看有哪些消费队列
kafka-consumer-groups.sh --bootstrap-server 10.131.11.243:9092 --list
# 查看消费队列详细信息
kafka-consumer-groups.sh --bootstrap-server 10.131.11.243:9092  --group logstash --describe
# 查看topic内容
kafka-console-consumer.sh --bootstrap-server 10.131.11.243:9092 --topic access-log --from-beginning

```

```shell

docker run -dit --restart always --name zookeeper -p 2181:2181 -v /data/zookeeper/data:/apache-zookeeper-3.5.9-bin/data -v /data/zookeeper/conf:/apache-zookeeper-3.5.9-bin/conf -v /data/zookeeper/zk_data:/data/zookeeper --network host zookeeper:3.5.9

docker run -dit --restart always --name zookeeper -p 2181:2181 \
-v /data/zookeeper/conf:/apache-zookeeper-3.5.9-bin/conf \
-v /data/zookeeper/data:/apache-zookeeper-3.5.9-bin/data \
--network host zookeeper:3.5.9

```


### 三、Ansible

#### 1、操作命令

```shell
# 查看所有主机列表
ansible all --list-hosts
ansible-inventory --list -y
```
```shell
# 模块使用
ansible all -m ping -o
ansible all -m shell -a "ls -a" -o
# yum 模块
ansible all -m yum -a "state=present name=iptables-services" -o	# 等同installed
ansible all -m yum -a "state=rabsent name=xxxx disable_gpg_check=yes" -o	# 等同removed
# copy模块
ansible all -m copy -a "src=/etc/chrony.conf dest=/etc/chrony.conf"
```






```shell
# 启动pg使用最新pg_dump命令
docker run -dit --name postgres2 -e POSTGRES_PASSWORD=12345678 \
  -p 5432:5432 -v /efs/pg:/var/lib/postgresql/data postgres
```
```sql
# 导出所有
pg_dumpall -h xx.xx.xx.xx -U idpg -p 5432 -W --inserts > bak.sql

# 导出整个库(表结构和数据 sequcence)
pg_dump -h xx.xx.xx.xx -p 16430 -U idpg -W database-name --inserts > id_auth.sql
# 导入整个库
psql -h xx.xx.xx.xx -p 5432 -U idpg -W database-name -f ./id_auth.sql


# 导出单个表
pg_dump -h xx.xx.xx.xx -U idpg -p 5432 -W database-name --schema=public -t tables-name --inserts > xxx.sql
# 导入单个表
psql -h xx.xx.xx.xx -U idpg -p 5432 -d database-name -f ./xxxx.sql
```





```shell
# 部署Rancher server
docker run -d --privileged --restart=unless-stopped \
  -p 9080:80 -p 9443:443 \
  -v /data/rancher/data:/var/lib/rancher \
  rancher/rancher:v2.5.14


# 重制Rancher 密码
docker exec -ti <container_id> reset-password
```
