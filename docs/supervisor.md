# supervisor

使用supervisor管理启动服务

## 1、使用supervisor托管etcd服务

### 1、安装supervisor
```
yum install supervisor -y
systemctl enable supervisord.service
systemctl start supervisord.service
```

### 2、创建etcd启动脚本
```
# 创建etcd用户
useradd -s /sbin/nologin -M etcd
```

```
# 添加etcd启动脚本
cat > /opt/src/etcd/etcd-startup.sh <<EOF
/opt/src/etcd/etcd --name etcd-03 \
  --listen-peer-urls https://192.168.181.213:2380 \
  --listen-client-urls https://192.168.181.213:2379,http://127.0.0.1:2379 \
  --quota-backend-bytes 8000000000 \
  --advertise-client-urls https://192.168.181.213:2379,http://127.0.0.1:2379 \
  --initial-cluster etcd-01=https://192.168.181.211:2380,etcd-02=https://192.168.181.212:2380,etcd-03=https://192.168.181.213:2380 \
  --data-dir /opt/src/etcd/data/ \
  --initial-advertise-peer-urls https://192.168.181.213:2380 \
  --ca-file /opt/src/etcd/pki/ca.pem \
  --cert-file /opt/src/etcd/pki/etcd.pem \
  --key-file /opt/src/etcd/pki/etcd-key.pem \
  --client-cert-auth   --trusted-ca-file /opt/src/etcd/pki/ca.pem \
  --peer-ca-file /opt/src/etcd/pki/ca.pem \
  --peer-cert-file /opt/src/etcd/pki/etcd.pem \
  --peer-key-file /opt/src/etcd/pki/etcd-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /opt/src/etcd/pki/ca.pem \
  --log-output stdout
EOF
chmod +x /opt/src/etcd/etcd-startup.sh
```

### 3、创建supervisor启动etcd配置
```
cat > /etc/supervisord.d/etcd-server.ini <<EOF
[program:etcd-01]
command=/opt/src/etcd/etcd-startup.sh                           ; the program (relative uses PATH, can take args)
numprocs=1                                                      ; number of processes copies to start (def 1)
directory=/opt/src/etcd                                         ; directory to cwd to before exec (def no cwd)
autostart=true                                                  ; start at supervisord start (default: true)
autorestart=true                                                ; retstart at unexpected quit (default: true)
startsecs=22                                                    ; number of secs prog must stay running (def. 1)
startretries=3                                                  ; max # of serial start failures (default 3)
exitcodes=0,2                                                   ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                                 ; signal used to kill process (default TERM)
stopwaitsecs=10                                                 ; max num secs to wait b4 SIGKILL (default 10)
user=etcd                                                       ; setuid to this UNIX account to run the program
redirect_stderr=false                                           ; redirect proc stderr to stdout (default false)
stdout_logfile=/opt/src/etcd/logs/etcd.stdout.log               ; stdout log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                    ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                        ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                     ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                     ; emit events on stdout writes (default false)
stderr_logfile=/opt/src/etcd/logs/etcd.stderr.log               ; stderr log path, NONE for none; default AUTO
stderr_logfile_maxbytes=64MB                                    ; max # logfile bytes b4 rotation (default 50MB)
stderr_logfile_backups=4                                        ; # of stderr logfile backups (default 10)
stderr_capture_maxbytes=1MB                                     ; number of bytes in 'capturemode' (default 0)
stderr_events_enabled=false                                     ; emit events on stderr writes (default false)
EOF
```

### 4、启动etcd并检查状态

***提前拷贝相关证书,否则启动报错***

```
chown -R etcd:etcd /opt/src/etcd-v3.2.31
chown -R etcd:etcd /opt/src/etcd
# 更新supervisor配置
supervisorctl update
etcd-01: added process group
# 查看启动状态
supervisorctl status
etcd-01                          RUNNING   pid 12339, uptime 0:00:45
```



## 2、配置apiserver启动

```
cat > /opt/src/kubernetes/server/bin/kube-apiserver.sh <<EOF
#!/bin/bash
/opt/src/kubernetes/server/bin/./kube-apiserver \
  --apiserver-count 1 \
  --enable-admission-plugins NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \
  --bind-address 192.168.181.194 \
  --authorization-mode RBAC,Node \
  --enable-bootstrap-token-auth \
  --tls-cert-file /opt/src/kubernetes/server/bin/certs/apiserver.pem \
  --tls-private-key-file /opt/src/kubernetes/server/bin/certs/apiserver-key.pem \
  --requestheader-client-ca-file /opt/src/kubernetes/server/bin/certs/ca.pem \
  --client-ca-file /opt/src/kubernetes/server/bin/certs/ca.pem \
  --etcd-cafile /opt/src/kubernetes/server/bin/certs/ca.pem \
  --etcd-certfile /opt/src/kubernetes/server/bin/certs/client.pem \
  --etcd-keyfile /opt/src/kubernetes/server/bin/certs/client-key.pem \
  --etcd-servers https://192.168.181.194:2379,https://192.168.177.238:2379,https://192.168.176.107:2379 \
  --service-cluster-ip-range 10.10.0.0/16 \
  --service-node-port-range 3000-29999 \
  --service-account-key-file /opt/src/kubernetes/server/bin/certs/ca-key.pem \
  --target-ram-mb=1024
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path /data/logs/kubernetes/kube-apiserver/ \
  --audit-policy-file /opt/src/kubernetes/server/bin/conf/audit.yaml \
  --log-dir  /data/logs/kubernetes/kube-apiserver/ \
  --kubelet-client-certificate /opt/src/kubernetes/server/bin/certs/client.pem \
  --kubelet-client-key /opt/src/kubernetes/server/bin/certs/client-key.pem \
  --v=2
EOF
```
