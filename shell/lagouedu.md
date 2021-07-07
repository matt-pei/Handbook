# shell命令合集
## 1、空间分析:
### 1磁盘空间不足快速定位日志目录
```
du -x --max-depth=1 /path | sort -k1 -nr 
-x 跳过其他文件系统
--max-depth=1 统计出/path目录下第一级目录中所有文件大小
sort  -k 具体按照那一列进行排序
-n 表示只对数值排序
-r 表示反向排序
sort -k1 -nr 表示指定第一列数据大小做反向排序
```
### 2系统碎片导致inode资源不足
```
find -type f | awk -F / -v OFS=/ '{$NF="";dir[$0]++}END{for(i in dir)print dir[i]" " i}' | sort -k1 -nr | head
```
## 2、文件操作
### 1批量查找文件作内容替换
```
find ./ -type f -name xxxx.xml -exec sed -i "s/aaaa/bbbb/g" {} \
```
### 2文件批量打包拷贝
```
(find /path -name "*.txt" | xargs tar -zcf test.tar) && cp -f test.tar /path
```
## 3、网络链接状态分析
### 1用户请求网络链接状态分析
```
netstat -n | awk '/^tcp/ {++s[$NF]END{for(a in S)print a,S[a]}}'
```
### 2提取主机上IP
```
ip a | grep "global" | awk '{print $2}' | awk -F / '{print $1}'
ip a 查看网卡信息
通过grep条件过滤
在通过awk实现第二列内容过滤
最后通过awk指定 / 作为分隔符来打印第一列信息
```

# 二、Nginx基础配置优化
## 基础配置优化
### 1cpu亲和性优化
```
nginx运行时会启动1个master进程几多个worker进程,worker进程负责处理请求
auto (worker_cpu_affinity) 或者手动
```
### 2nginx模型优化
```
IO事件流模型  epoll模型
nginx处理大规模请求时,为了提高并发效率需采用异步非阻塞模型
epoll本身是以异步非阻塞模型来处理请求（kernel 2.6版本后提出）

epoll与select优势
epoll处理事件流模型是线程安全的
epoll和select相比 调用fd文件描述符时使用了mmap共享用户和内核的部分空间,提高了效率
epoll基于事件驱动 避免频繁扫描文件描述符,可以调用callback回调函数,效率更高
取消了select模型里面单个进程能够监视的文件描述符的数量存在最大限制(1024)

events{}配置还有一个优化的地方worker_connections在高并发的时候调大
```
### 3nginx传输方式优化
```
零拷贝
nginx在http配置中默认添加一个sendfile on; 所谓零拷贝并不代表拷贝,而是做到了文件的内核态到用户态的零拷贝
```
### 4nginx文件压缩优化
```
文件压缩
主要通过gzip方式进行设置
gzip on 打开后端压缩能能
gzip_buffer 16 8k 设置nginx在处理文件压缩是的内存空间
gzip_comp_level 6 设置nginx在处理压缩时的压缩等级
gzip_http_version 1.1 表示只对http 1.1版本协议进行压缩
gzip_min_length 256 表示只有大于256字节的长度时才进行压缩否则不压缩
gzip_proxied any 代表nginx作为反向代理时 根据后端服务器时返回信息设置gzip压缩策略
gzip_vary on 表示是否发送vary：Accept_Enconding响应头字段 通知接收方响应使用了gzip压缩
application/vnd.ms-fontobject image/x-icon; gzip压缩类型
gzip_disble "msie6" 表示关系IE6的压缩
```
## 缓存配置优化
### 1浏览器缓存优化
```
把静态元素缓存到客户端
通过nginx配置expires配置菜单进行设置 加具体的时间或者特定意义的数值 -1表示永久缓存 max设置最大缓存（默认缓存周期为10年）
```
### 2代理缓存优化
```
proxy_cache_path /path/to/cache/ level 1:2 keys_zone=my_cache:10m
max_size=10g inactive=60mloation / {
    proxy_cache my_cache;
}

proxy_cache_path 表示在本地分配哪个路径来缓存后台文件元素
cache_level 表示放文件的分层方式
my_cache:10m max_size 缓存单个文件的最大大小 还有失效等 另外一块设置表示在proxy_cache的时候 通过location引用到cache的名称
```
### 3http ssl缓存优化
```
配置原理
当浏览器跟服务端建立第一次加密证书验证会话后
服务端会给客户端浏览器缓存一个SessionKey
如果客户端跟服务端再次断开连接 这时浏览器就可以拿着SessionKey直接跟服务端进行交互只需要进行一个校验 就可以开始传输数据

ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```
### 4kv服务缓存优化
```
打开文件缓存
元数据的作用就是缓存打开用户所请求的静态元素的文件路径等信息
open_file_cache max=1000 inactive=20s;
open_file_cache_valid 30s;
open_file_cache_min_user 2;
open_file_cache_errors on;
```

# 三、Nginx负载均衡

## 应用架构
### 1分层入口代理架构
```
# 入口层
L4 L7
# 逻辑服务层
# 数据层
```
### 2服务注册发现代理架构
## 负载均衡常见问题
### 1客户端IP地址获取问题
```
1、在nginx负载均衡基础上添加一个转发到后端的set的head信息 把用户的IP信息通过X-Forwarded-For方式传递出去
2、添加一个X-Real自定义头 自定义的头可以随意命名 一般情况下命名为X-Real_IP 把用户的真实四层IP地址赋值给它
```
### 2域名携带问题
```
proxy_set_header Host $host;
proxy_set_header Host www.xxxx.com
```
### 3负载均衡导致session丢失问题
```
1、session保持
把负载均衡策略基于原有轮询数的基础上 改用ip_hash、URL_hash来解决
ip_hash就是基于用户IP来做hash 一个用户的请求统一分发到一台机器上
URL_hash 用于用户请求固定页面时 将用户请求固定到具体后端上 就保证了session不会丢失
2、session复制
session复制是在后台应用基础上 让session之间可以传播的方式进行复制 也就是App1上如果有一个session 那么它可以复制给App2 App3 无论怎样轮询 三个App上都会有同样的session信息 不至于因为轮询熬制会话失败
3、session共享
Session共享是由程序完成 把session信息不放在本地
通过应用程序把Session信息放入到共享的k/v存储中 这样就不会产生session丢失情况了

upstream app_server
ip_hash / hash $request_url;
```
### 4动态负载均衡问题
### 5真是的Realserver状态检测
```
默认情况下 Nginx基于TCP端口和连接方式检测
也就是在服务ping不通 或无法建立TCP连接
以及端口服务完全不可用的状态下 才会认为这个服务不可用

第三方模块nginx_upstream_check_module
check interval=3000 rise=2 fall=5 timeout=1000 type=http; //定义检查间隔、周期、时间
check_keepalive_requests 100; //一个链接发送的请求数
check_http_send?HEAD /HTTP/1.1\r\nConnection:keep-alive\r\n\r\n?; //定义健康检查的方式
check_http_expect_alive http_2xx http_3xx; //判断返回状态码
```

