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
#!/bin/bash
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

***证书分别为：ca.pem/etcd.pem/etcd-key.pem***

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

---

## 2、配置apiserver启动

### 1、创建apiserver启动脚本

***提前拷贝相关证书,否则启动报错***

***证书分别为：ca.pem/ca-key.pem/client.pem/client-key.pem/apiserver.pem/apiserver-key.pem/***

> WARNING
>
> 在此下面启动脚本中`service-cluster-ip-range`参数设置Ip段的时候,是给集群中`service`设置的,与安装kube-controller启动脚本中等同参数

```
cat > /opt/src/kubernetes/server/bin/kube-apiserver.sh <<EOF
#!/bin/bash
/opt/src/kubernetes/server/bin/kube-apiserver \\
  --apiserver-count 1 \\
  --enable-admission-plugins NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,MutatingAdmissionWebhook,ValidatingAdmissionWebhook,ResourceQuota \\
  --bind-address 192.168.181.211 \\
  --authorization-mode RBAC,Node \\
  --enable-bootstrap-token-auth \\
  --tls-cert-file /opt/src/kubernetes/server/bin/pki/apiserver.pem \\
  --tls-private-key-file /opt/src/kubernetes/server/bin/pki/apiserver-key.pem \\
  --requestheader-client-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --client-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --etcd-cafile /opt/src/kubernetes/server/bin/pki/ca.pem \\
  --etcd-certfile /opt/src/kubernetes/server/bin/pki/client.pem \\
  --etcd-keyfile /opt/src/kubernetes/server/bin/pki/client-key.pem \\
  --etcd-servers https://192.168.181.211:2379,https://192.168.181.212:2379,https://192.168.181.213:2379 \\
  --service-cluster-ip-range 10.10.0.0/16 \\
  --service-node-port-range 3000-29999 \\
  --service-account-key-file /opt/src/kubernetes/server/bin/pki/ca-key.pem \\
  --target-ram-mb=1024 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path /data/kubernetes/logs/kube-apiserver/ \\
  --audit-policy-file /opt/src/kubernetes/server/bin/conf/audit.yaml \\
  --log-dir  /data/kubernetes/logs/kube-apiserver/ \\
  --kubelet-client-certificate /opt/src/kubernetes/server/bin/pki/client.pem \\
  --kubelet-client-key /opt/src/kubernetes/server/bin/pki/client-key.pem \\
  --v=2
EOF

chmod +x /opt/src/kubernetes/server/bin/kube-apiserver.sh
```

### 2、创建supervisor启动etcd配置
```
# 创建apiserver日志目录
mkdir -p /data/kubernetes/logs/kube-apiserver/

cat > /etc/supervisord.d/kube-apiserver.ini <<EOF
[program:kube-apiserver-7-21]
command=/opt/src/kubernetes/server/bin/kube-apiserver.sh        ; the program (relative uses PATH, can take args)
numprocs=1                                                      ; number of processes copies to start (def 1)
directory=/opt/src/kubernetes/server/bin                        ; directory to cwd to before exec (def no cwd)
autostart=true                                                  ; start at supervisord start (default: true)
autorestart=true                                                ; retstart at unexpected quit (default: true)
startsecs=30                                                    ; number of secs prog must stay running (def. 1)
startretries=3                                                  ; max # of serial start failures (default 3)
exitcodes=0,2                                                   ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                                 ; signal used to kill process (default TERM)
stopwaitsecs=10                                                 ; max num secs to wait b4 SIGKILL (default 10)
user=root                                                       ; setuid to this UNIX account to run the program
redirect_stderr=true                                            ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/kubernetes/logs/kube-apiserver/apiserver.stdout.log        ; stderr log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                    ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                        ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                     ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                     ; emit events on stdout writes (default false)
EOF
```

### 3、启动etcd并检查状态

```
# 更新supervisor配置
supervisorctl update
# 查看启动状态
supervisorctl status
etcd-01                          RUNNING   pid 714, uptime 0:00:45
kube-apiserver                   RUNNING   pid 715, uptime 0:00:45

netstat -anpt | grep 6443
tcp        0      0 192.168.181.211:6443    0.0.0.0:*               LISTEN      17197/kube-apiserve
tcp        0      0 192.168.181.211:6443    192.168.181.211:39948   ESTABLISHED 17197/kube-apiserve
tcp        0      0 192.168.181.211:39948   192.168.181.211:6443    ESTABLISHED 17197/kube-apiserve
或
netstat -lntpu | grep kube-api
tcp        0      0 192.168.181.211:6443    0.0.0.0:*               LISTEN      17197/kube-apiserve
tcp        0      0 127.0.0.1:8080          0.0.0.0:*               LISTEN      17197/kube-apiserve
```

---

## 3、配置kube-controller启动

### 1、创建kube-controller启动脚本

> ⚠️注意
>
> 下面启动脚本中`service-cluster-ip-range`参数一定要与安装apiserver启动相同参数一致

```
# 创建日志目录
mkdir -p /data/kubernetes/logs/kube-controller-manager

cat > /opt/src/kubernetes/server/bin/kube-controller-manager.sh <<EOF
#!/bin/bash
/opt/src/kubernetes/server/bin/kube-controller-manager \
  --cluster-cidr 172.16.0.0/16 \
  --leader-elect true \
  --log-dir /data/kubernetes/logs/kube-controller-manager \
  --master http://127.0.0.1:8080 \
  --service-account-private-key-file /opt/src/kubernetes/server/bin/pki/ca-key.pem \
  --service-cluster-ip-range 10.10.0.0/16 \
  --root-ca-file /opt/src/kubernetes/server/bin/pki/ca.pem \
  --v 2
EOF

chmod +x /opt/src/kubernetes/server/bin/kube-controller-manager.sh
```

### 2、创建supervisor启动配置
```
cat > /etc/supervisord.d/kube-conntroller-manager.ini <<EOF
[program:kube-controller-manager]
command=/opt/src/kubernetes/server/bin/kube-controller-manager.sh                 ; the program (relative uses PATH, can take args)
numprocs=1                                                                        ; number of processes copies to start (def 1)
directory=/opt/src/kubernetes/server/bin/                                         ; directory to cwd to before exec (def no cwd)
autostart=true                                                                    ; start at supervisord start (default: true)
autorestart=true                                                                  ; retstart at unexpected quit (default: true)
startsecs=30                                                                      ; number of secs prog must stay running (def. 1)
startretries=3                                                                    ; max # of serial start failures (default 3)
exitcodes=0,2                                                                     ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                                                   ; signal used to kill process (default TERM)
stopwaitsecs=10                                                                   ; max num secs to wait b4 SIGKILL (default 10)
user=root                                                                         ; setuid to this UNIX account to run the program
redirect_stderr=true                                                              ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/kubernetes/logs/kube-controller-manager/controller.stdout.log  ; stderr log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                                      ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                                          ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                                       ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                                       ; emit events on stdout writes (default false)
EOF
```

### 3、查看kube-controller-manager启动
```
# 更新kube-controller-manager配置
supervisorctl update
kube-controller-manager: added process group
# 查看启动状态
supervisorctl status
etcd-01                          RUNNING   pid 714, uptime 1 day, 0:39:08
kube-apiserver                   RUNNING   pid 715, uptime 1 day, 0:39:08
kube-controller-manager          RUNNING   pid 3127, uptime 0:01:13
```

---

## 3、配置kube-scheduler启动

### 1、创建启动脚本
```
mkdir -p /data/kubernetes/logs/kube-scheduler

cat > /opt/src/kubernetes/server/bin/kube-scheduler.sh <<EOF
#!/bin/bash
/opt/src/kubernetes/server/bin/kube-scheduler \\
  --leader-elect true  \\
  --log-dir /data/logs/kubernetes/kube-scheduler \\
  --master http://127.0.0.1:8080 \\
  --v 2
EOF

chmod +x /opt/src/kubernetes/server/bin/kube-scheduler.sh
```

### 2、配置supervisor启动
```
cat > /etc/supervisord.d/kube-scheduler.ini <<EOF
[program:kube-scheduler]
command=/opt/src/kubernetes/server/bin/kube-scheduler.sh                 ; the program (relative uses PATH, can take args)
numprocs=1                                                               ; number of processes copies to start (def 1)
directory=/opt/src/kubernetes/server/bin                                 ; directory to cwd to before exec (def no cwd)
autostart=true                                                           ; start at supervisord start (default: true)
autorestart=true                                                         ; retstart at unexpected quit (default: true)
startsecs=30                                                             ; number of secs prog must stay running (def. 1)
startretries=3                                                           ; max # of serial start failures (default 3)
exitcodes=0,2                                                            ; 'expected' exit codes for process (default 0,2)
stopsignal=QUIT                                                          ; signal used to kill process (default TERM)
stopwaitsecs=10                                                          ; max num secs to wait b4 SIGKILL (default 10)
user=root                                                                ; setuid to this UNIX account to run the program
redirect_stderr=true                                                     ; redirect proc stderr to stdout (default false)
stdout_logfile=/data/kubernetes/logs/kube-scheduler/scheduler.stdout.log ; stderr log path, NONE for none; default AUTO
stdout_logfile_maxbytes=64MB                                             ; max # logfile bytes b4 rotation (default 50MB)
stdout_logfile_backups=4                                                 ; # of stdout logfile backups (default 10)
stdout_capture_maxbytes=1MB                                              ; number of bytes in 'capturemode' (default 0)
stdout_events_enabled=false                                              ; emit events on stdout writes (default false)
EOF
```

### 3、查看supervisor
```
supervisorctl update
kube-scheduler: added process group

supervisorctl status
etcd-01                          RUNNING   pid 714, uptime 1 day, 0:56:51
kube-apiserver                   RUNNING   pid 715, uptime 1 day, 0:56:51
kube-controller-manager          RUNNING   pid 3127, uptime 0:18:56
kube-scheduler                   RUNNING   pid 22064, uptime 0:00:32
```

## 4、给kubectl创建软连接
```
ln -s /opt/src/kubernetes/server/bin/kubectl /usr/local/sbin/
```

