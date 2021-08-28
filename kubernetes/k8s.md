# Kubernetes CKA 认证

### cka & ckad 

3个CKA认证 可申请KCSP（k8s服务器提供商）

### 考试内容
```
满分100 74及格
24道题

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
```
kube-apiServer 用于暴露k8 API 资源请求/调度操作
etcd  默认存储系统、保存集群数据
kube-controller-manager 运行管理控制器 管理集群线程
    节点Node
    副本Replication
    端点Endpoints
    Service Account和Token：namespace
kube-scheduler  做调度分配 根据请求资源做调度
```
#### node
```
kubelet 维护容器生命周期 Volumen 网络（CNI）
kube-proxy  在主机上维护网络规则 iptables/ipvs
container Runtime

coredns/kube-dns    提供DNS
Ingress 提供七层服务
```

### pod调度流程
```
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
```
### kubernetes网络方案
            overlay             L3routing               upderlay
描述        

### 搭建Kubernetes集群 工具
> Kubeadm
>
> Kops
>
> Kubespray


### 命令补全
```
yum -y install bash-completion
kubectl completion -h
# 临时生效
source <(kubectl completion bash)
# 永久生效
echo 'source <(kubectl completion bash)' >>~/.bashrc
# echo "source <(kubectl completion bash)" >> /root/.bashrc
kubectl completion bash >/etc/bash_completion.d/kubectl
```
```
# 查看Token
kubeadm token list
# 创建Token
kubeadm token create
# 删除Token
kubeadm token delete
# 获取ca证书sha256编码hash值
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2> /dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
```

### 资源信息
```
kubectl get nodes
kubectl get nodes -o wide
kubectl describe nodes node01 | less
kubectl get nodes --show-labels
kubectl label node node01 node-role.kubernetes.io/node=
kubectl label node node01 node-role.kubernetes.io/node-
```

### 命令空间
```
kubectl -n kube-system get pod
kubectl create namespace xxx
kubectl get namespace
kubectl delete namespace xxx
kubectl apply -f xxx.yaml
kubectl delete -f xxx.yaml
```

### pod
```
kubectl explain pod
kubectl delete pod xxxx
kubectl exec -it xxxx bash
kubectl exec -it xxxx -c xxxx bash
kubectl exec -it xxxx -c xxxx -- ls /root/
```

```
kubectl run xxxx --image=xxx --image-pull-policy=IfNotPresent
kubectl get deployments. xxxx -o yaml | less
kubectl run xxxx --image=xxx --image-pull-policy=IfNotPresent --replicas=2
kubectl set image deployment xxxxx nginx=xxx:v2 --record
kubectl rollout status deployment xxxxx
kubectl rollout history deployment xxxxx
kubectl rollout history deployment xxxx --revision=1
kubectl rollout undo deployment xxxx --to-revision=1
kubectl scale deployment xxxxx --replicas=5
```

```
kubectl get daemonsets
kubectl expose deployment xxxx --target-port=xx --port=xx --type=ClusterIP
kubectl get service
kubectl get endpoints
```

```
kubectl get job
kubectl get configmap
kubectl describe configmap xxxx
kubectl create configmap --form-file= --from-file=  xxxx
kubectl create secret generic xxxx --from-file= --from-file= 
kubectl describe secrets xxxx

kubectl get pv
kubectl get pvc
kubectl delete pvc xxx
```





## Kubeadm部署

cat /sys/class/dmi/id/product_uuid


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system




