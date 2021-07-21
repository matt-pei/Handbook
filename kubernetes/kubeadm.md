# Kubeadm 安装


```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 安装指定版本
yum list kubeadm kubectl kubelet --showduplicates
yum -y install kubeadm-1.20.0 kubectl-1.20.0 kubelet-1.20.0
systemctl enable kubelet && systemctl start kubelet
```

```
kubeadm init --apiserver-advertise-address=172.25.188.66 \
             --image-repository registry.aliyuncs.com/google_containers \
             --pod-network-cidr=192.168.0.0/16

export KUBECONFIG=/etc/kubernetes/admin.conf

# 检查Kubernetes集群证书过期
kubeadm certs check-expiration
```

```
# 安装Flannel
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# 安装Calico
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml
```
