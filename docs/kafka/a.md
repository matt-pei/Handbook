
```
# 配置kafka服务systemd启动
cat > /etc/systemd/system/kafka-log.service <<EOF
[Unit]
Description=Apache Kafka server
Documentation=https://kafka.apache.org/documentation/
After=network.target

[Service]
Type=simple
Environment=
ExecStart=/usr/share/kafka-log/bin/kafka-server-start.sh /usr/share/kafka-log/config/server.properties
ExecStop=/usr/share/kafka-log/bin/kafka-server-stop.sh
Restart=always
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
```
```
# 配置kafka服务systemd启动
cat > /etc/systemd/system/kafka-hdms.service <<EOF
[Unit]
Description=Apache Kafka server
Documentation=https://kafka.apache.org/documentation/
After=network.target

[Service]
Type=simple
Environment=
ExecStart=/usr/share/kafka-hdms/bin/kafka-server-start.sh /usr/share/kafka-hdms/config/server.properties
ExecStop=/usr/share/kafka-hdms/bin/kafka-server-stop.sh
Restart=always
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
```



