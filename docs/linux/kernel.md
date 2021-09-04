linux内核参数调优
```
kernel.panic = 5                              #内核崩溃5s后重启
kernel.core_uses_pid = 1                      #控制core文件的文件名中是否添加pid作为扩展。
net.core.netdev_max_backlog = 10000           #允许队列最大的数据包数
net.core.rmem_max = 8388608                   #接收套接字缓冲区最大大小
net.core.somaxconn = 1024                     #每个端口最大的监听队列的长度
net.core.wmem_max = 8388608                   #发送套接字缓冲区最大大小
net.ipv4.ip_forward = 0                       #禁用转发
net.ipv4.ip_local_port_range = 1024 65000     #动态端口范围
net.ipv4.tcp_fin_timeout = 30                 #FIN-WAIT-2状态最大时间
net.ipv4.tcp_keepalive_intvl = 2              #当探测没有确认时，重新发送探测的频度
net.ipv4.tcp_keepalive_probes = 2             #在认定连接失效之前，发送多少个TCP的keepalive探测包
net.ipv4.tcp_keepalive_time = 60              #发送keepalive消息的频度，60s
net.ipv4.tcp_max_syn_backlog = 8192           #
net.ipv4.tcp_max_tw_buckets = 18500           #系统允许最大timewait socket数量
net.ipv4.tcp_rmem = 4096 87380 8388608        #接收套接字缓冲区最小 默认 和最大
net.ipv4.tcp_wmem = 4096 65536 8388608        #写入套接字缓冲区最小 默认 和最大
net.ipv4.tcp_sack = 0                         #表示是否启用有选择的应
net.ipv4.tcp_syn_retries = 2                  #放弃连接前发送syn的次数
net.ipv4.tcp_syncookies = 1                   #当出现SYN等待队列溢出时，启用cookies来处理，可防范少量SYN攻击
net.ipv4.tcp_timestamps = 0                   #时间戳可以避免序列号的卷绕，关闭掉。
net.ipv4.tcp_tw_recycle = 1                   #开启TIME_WAIT的快速回收
net.ipv4.tcp_tw_reuse = 1                     #开启TIME_WAIT的重用
net.ipv4.tcp_window_scaling = 0               #支持更大的TCP窗口
vm.max_map_count=262144                       #一个进程最大拥有的虚拟内存数量
vm.swappiness = 1                             #越小，越不积极使用swap
```
