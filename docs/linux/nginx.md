# Nginx配置

## 从源代码构建Nginx

使用configure命令配置构建,它定义了系统的各个方面，包括允许nginx用于连接处理的方法。最后，它会创建一个Makefile。

<details>
<summary>该configure命令支持以下参数：</summary>

** aaaa **

</details>

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


