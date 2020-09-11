# supervisor

使用supervisor管理启动服务

## 使用supervisor托管etcd服务

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
/opt/src/etcd/etcd --name etcd01 \
  --listen-peer-urls https://192.168.181.194:2380 \
  --listen-client-urls https://192.168.181.194:2379,http://127.0.0.1:2379 \
  --quota-backend-bytes 8000000000 \
  --advertise-client-urls https://192.168.181.194:2379,http://127.0.0.1:2379 \
  --initial-cluster etcd01=https://192.168.181.194:2380,etcd02=https://172.31.205.45:2380,etcd03=https://172.31.205.46:2380 \
  --data-dir /opt/src/etcd/data/ \
  --initial-advertise-peer-urls https://192.168.181.194:2380 \
  --ca-file /opt/src/etcd/cert/ca.pem \
  --cert-file /opt/src/etcd/cert/etcd.pem \
  --key-file /opt/src/etcd/cert/etcd-key.pem \
  --client-cert-auth \
  --trusted-ca-file /opt/src/etcd/cert/ca.pem \
  --peer-ca-file /opt/src/etcd/cert/ca.pem \
  --peer-cert-file /opt/src/etcd/cert/etcd.pem \
  --peer-key-file /opt/src/etcd/cert/etcd-key.pem \
  --peer-client-cert-auth \
  --peer-trusted-ca-file /opt/src/etcd/cert/ca.pem \
  --log-output stdout
EOF
chmod +x /opt/src/etcd/etcd-startup.sh
```

### 3、创建supervisor启动etcd配置
```
cat > /etc/supervisord.d/etcd-server.ini <<EOF
[program:etcd01]
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
```
chown -R etcd.etcd /opt/src/etcd-v3.2.31
chown -R etcd.etcd /opt/src/etcd
# 更新supervisor配置
supervisorctl update
etcd01: added process group
# 查看启动状态
supervisorctl status
etcd01                            RUNNING   pid 17299, uptime 0:00:27
```

