# Nginx配置

```
upstream模块
upstream name {
    ip_hash;
    server 192.168.1.100:8000;
    server 192.168.1.100:8001 down;
    server 192.168.1.100:8002 max_fails=3;
    server 192.168.1.100:8003 fail_timeout=20s;
    server 192.168.1.100:8004 max_fails=3 fail_timeout=20s;
}
```

```
ip_hash：指定请求调度算法，默认是weight权重轮询调度，可以指定
server host:port：分发服务器的列表配置
-- down：表示该主机暂停服务
-- max_fails：表示失败最大次数，超过失败最大次数暂停服务
-- fail_timeout：表示如果请求受理失败，暂停指定的时间之后重新发起请求
```


