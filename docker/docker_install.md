## 安装docker服务
### 一、关闭selinux和防火墙
```
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
sed -i 's/^SELINUX=permissive$/SELINUX=disabled/' /etc/selinux/config
```
#### 关闭firewalld服务
```
systemctl disable firewalld.service
systemctl stop firewalld.service
```
### 二、安装时间服务和工具包
#### 1、移动CentOS自带repo源
```
mkdir -pv /data
mkdir -pv /etc/yum.repos.d/repo.backup
yes | mv /etc/yum.repos.d/CentOS-* /etc/yum.repos.d/repo.backup
yes | mv /etc/yum.repos.d/repo.backup/CentOS-Base* /etc/yum.repos.d/
```
#### 2、安装常用工具
```
yum -y install vim wget net-tools htop pciutils epel-release tcpdump iptraf
yum -y install bash-completion chrony lrzsz iotop
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
```
#### 3、启动时间服务器
```
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
```
#### 4、关闭swap交换分区
```
swapoff -a          # 临时关闭
# vim /etc/fstab    # 永久关闭,注释swap行
sed -i 's/.*swap.*/#&/' /etc/fstab
```
### 三、安装docker服务
#### 1、卸载旧docker版本
```
# https://docs.docker.com/install/linux/docker-ce/centos/
yum -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
# 删除旧docker存储库
rm -rf /etc/yum.repos.d/docker*.repo
```
##### From https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker

#### Install Docker CE
#### Set up the repository
#### Install required packages.
```
yum install -y yum-utils device-mapper-persistent-data lvm2
```
#### Add Docker repository.
```
yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo
```
#### Install Docker CE.
```
yum install -y \
  containerd.io-1.2.13 \
  docker-ce-19.03.8 \
  docker-ce-cli-19.03.8
# yum -y install docker-ce-19.03.4 docker-ce-cli-19.03.4 containerd.io-1.2.10
```
#### Create /etc/docker directory.
```
mkdir /etc/docker
```
#### Setup daemon.
```
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
  "insecure-registries" : ["registry.cloopen.net"],
  "live-restore": true
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
```
#### Restart Docker
```
systemctl daemon-reload
systemctl restart docker
systemctl enable docker
```

### 四、安装nvidia-docker
```
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
yum install -y nvidia-container-toolkit
systemctl restart docker
```
#### 测试GPU
```
#### Test nvidia-smi with the latest official CUDA image
docker run --gpus all nvidia/cuda:10.0-base nvidia-smi

# Start a GPU enabled container on two GPUs
docker run --gpus 2 nvidia/cuda:10.0-base nvidia-smi

# Starting a GPU enabled container on specific GPUs
docker run --gpus '"device=1,2"' nvidia/cuda:10.0-base nvidia-smi
docker run --gpus '"device=UUID-ABCDEF,1"' nvidia/cuda:10.0-base nvidia-smi

# Specifying a capability (graphics, compute, ...) for my container
# Note this is rarely if ever used this way
docker run --gpus all,capabilities=utility nvidia/cuda:10.0-base nvidia-smi
```

#### 动态修改容器资源
```
docker container update  gitlabseafilegit_gitlab_1_66166xxx  --cpus="2" --memory="8g"  --memory-swap="-1"
```
#### 启动监控服务
```
docker run -dit \
  --restart=always \
  --name node-exporter \
  -p 9100:9100 \
  -v "/proc:/host/proc:ro" \
  -v "/sys:/host/sys:ro" \
  -v "/:/rootfs:ro" \
  --net="host" \
  prom/node-exporter:v0.18.1

docker run -dit \
  --restart=always \
  --name prometheus\
  -p 9090:9090 \
  -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml  \
  prom/prometheus

docker run -dit \
  --restart=always \
  --name grafana\
  -p 3000:3000 \
  --name=grafana \
  -v /opt/grafana-storage:/var/lib/grafana \
  grafana/grafana
 
docker run -dit \
    -p 9400:9400 \
    --gpus all \
    --restart always \
    --name dcgm-exporter \
    nvidia/dcgm-exporter:1.7.2
``` 
```
docker启动Jenkins
mkdir -pv /data/jenkins_home
docker run -dit \
    -u root \
    --restart always \
    -p 8080:8080 -p 50000:50000 \
    -v /data/jenkins_home:/var/jenkins_home \
    --name jenkins \
    jenkins/jenkins:2.239

docker启动gitlab
mkdir -pv /data/gitlab_storage
export GITLAB_HOME=/data/gitlab_storage

#docker启动Registry
mkdir -pv /data/registry_storage
docker run -dit \
    -p 5000:5000 \
    -v /data/registry_storage:/var/registry_storage \
    --name registry \
    --restart always \
    registry:2.7

#docker启动portainer
docker run -dit \
    -p 9000:9000 -p 8000:8000 \
    -v /data/portainer_storage:/data \
    -v /var/run/docker.sock:/var/run/docker.sock \
    --name portainer \
    --restart always \
    portainer/portainer:1.24.0
```
#### cAdvisor监控docker容器
```
docker run -dit \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/data/docker_store/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8181:8080 \
  --detach=true \
  --name=cadvisor \
  --privileged \
  --device=/dev/kmsg \
  google/cadvisor:v0.32.0
```

docker images  | grep none | awk '{print $3}' | xargs docker rmi
#更简单的方法
docker rmi `docker images -q -f dangling=true`
或
docker rmi $(docker images -q -f dangling=true)
