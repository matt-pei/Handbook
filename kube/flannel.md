# 🌐安装flannel

修改本地hosts文件
```
# 添加github解析
vim /etc/hosts
199.232.28.133  raw.githubusercontent.com
```

下载flannel配置文件
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


### 👷‍♀️错误排查
```
Q1:
E1010 09:21:44.549580       1 main.go:243] Failed to create SubnetManager: error retrieving pod spec for 'kube-system/kube-flannel-ds-x7x8j': Get "https://172.16.0.1:443/api/v1/namespaces/kube-system/pods/kube-flannel-ds-x7x8j": x509: certificate is valid for 127.0.0.1, 10.0.0.1, 192.168.10.231, 192.168.10.232, 192.168.10.233, 192.168.10.234, 192.168.10.235, not 172.16.0.1

A1:
在签发apiserver证书时,在hosts中添加172.16.0.1 Ip地址。重新签发apiserver后 在替换apiserver证书目录下的原证书，重启apiserver服务
```