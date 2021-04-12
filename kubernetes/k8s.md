# CKA 认证

### cka & ckad 

3个CKA认证 可申请KCSP（k8s服务器提供商）

### 考试内容
满分100 74及格
24道题
```
应用生命周期管理    8%
安装、配置和验证    12%
核心概念    19%
网络    11%
调度    5%
安全    12%
集群维护    11%
日志监控    5%
存储    7%
故障排除    10%
```
### kubernetes 架构

#### master
kube-apiServer 用于暴露k8 API 资源请求/调度操作
etcd  默认存储系统、保存集群数据
kube-controller-manager 运行管理控制器 管理集群线程
    节点Node
    副本Replication
    端点Endpoints
    Service Account和Token：namespace

#### node
kube-scheduler  做调度分配 根据请求资源做调度
kubelet 维护容器生命周期 Volumen 网络（CNI）
kube-proxy  在主机上维护网络规则 iptables/ipvs
container Runtime

coredns/kube-dns    提供DNS
Ingress 提供七层服务


### pod调度流程

         API server       ETCD       Scheduler    Kubelet     Docker
cretepod---->|----write---> |
     <-------| <----------- |           |           |           |
             | -----watch(new pod)----->|           |           |
             | <-------返回Node名--------|           |           |
             |-----write--->|           |           |           |
             |              |           |           |           |
             | ----------watch (bound pod)--------->|           |
             |              |           |           |----run--->|
             | <---------update pod status----------|           |
             | ----write--->|           |           |           |
             |              |           |           |           |

### kubernetes网络方案
            overlay             L3routing               upderlay
描述        

### 搭建Kubernetes集群 工具
Kubeadm

Kops

Kubespray




