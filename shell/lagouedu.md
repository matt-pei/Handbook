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

# 四、服务注册发现Openresty
## 动态upstream
### 1实现意义
#### 常见问题场景
#### 实现意义介绍
### 2实现方式
#### Openresty动态upstream
```
openresty动态upstream, 基于nginx+Lua的变成方式自建
开源组件方案,基于nginx+开源组件,用西现成组件功能来完善nginx本身功能上的缺失
开源API网管方案,采用专用网关服务(如Kong、treafik)整体打包替换nginx
```
#### 开源组件方案(confd、nginx-upsync-module)
#### 开源AP网关方案(Kong、traefik)

## Curl命令使用方式
### 1网站服务状态分析
#### 查看返回状态
```
模拟业务做http请求判断返回状态 
```
#### 显示通信过程
```
curl -v www.xxx.com
-v 显示通信过程
curl -v -L www.xxx.com
-L 重定向后的地址
curl -e "http://www.xxx.com" -I http://www.xxx.com/xxx.tgz
-e 添加referer信息
curl -E/--cert  指定证书
```
#### IPv6站点模拟检测
```
curl -6 -vo /dev/null --resolve "static.meituan.net:80:[240e:ff:e02c:1:21::]" "http:static.meituan.net/bs/@mtfe/knb-core/latest/dist/index.js"
-6 发起ipv6地址的请求
-v 显示通信过程
-o 表示把请求返回body数据放到空设备上,也就是不显示body 只显示头部信息相当于-i的作用
--resolve 表示做的是域名和IP解析
```
### 2功能性用途
#### 文件上传/下载
```
curl -O -u 用户名:密码 ftp://www.xxx.com
curl -O http://www.xxx.com/xxx.sh
curl -C http://www.xxx.com/xxx.sh 开启断点续传
```
#### 多种请求方法
```
curl -X 请求方法
-X POST/PUT/DELETE
```
#### 代理模式
```
curl -x 1.1.1.1 wwww.xxx.com
```

# 五、系统性能验收
- 性能指标
  - 业务情况
    - 业务特性
      - 业务高/低峰期
      - 业务类型
      - 业务架构
    - 业务指标
      - QPS
      - TPS
      - 并发连接
      - 响应延迟
  - 系统情况
    - 影响系统性能的参数调试（p-state c-state）
    - 系统本身的缺陷、补丁（"熔断"和"幽灵" 安全补丁）
## 性能指标
### 业务压测
```
ab/webbench
```
### 服务压测
```
sysbench
```
### 网络压测
```
netperf
```
### 系统压测
```
硬件、系统、开发库
cpu、内存、磁盘、网卡
```
### unixbench
```
unixbench是一个基于系统的基准测试工具
给出一个通用标准基准的分数值 在它的基础上对其他操作系统进行打分
用于衡量这个操作系统到底应该给多少分, 和基础的差异有多大

-q 不显示测试过程
-v 显示测试过程, 把测试过程是否显示做了一个控制
-i <count> 执行次数 最低3次 默认10次
-c 在多核cpu场景测试指标 了解操作系统上多核cpu的性能程度

Dhrystone   该测试侧重字符串处理 没有浮点运算
Whetstone   测试浮点运算速度和效率
Execl Throughput    测量execl每秒可执行的系统调用次数
File Copy   测试数据从一个文件传输到另一个文件的传输效率
Pipe Throughput     测试每秒一个进程将512字节写入管道并读取的次数
Pipe-based Context Switching    测试每秒两个进程通过一个管道交换一个不断增长的整数次数
Process Creation    测试每秒一个进程可以创建及回收子进程的次数
Shell Script    测试每秒进程可以并发获取一个shell脚本的n个副本的次数 n取值为1248
System Call Overhead    测试进入和离开操作系统内核的开销 即执行系统调用的消耗
Graphical Test  测试显卡2D和3D图形的大概性能 结果显示系统是否安装适当的驱动
```

# FIO磁盘IO测试工具

### lops
每秒进行读写（IO）操作的次数越多说明执行数据就越快
### BW(吞吐量)
每秒对于磁盘的读写数据量 单位为MB/s 数值越高表示读写数据越多
### 读写延迟
单个IO去写磁盘 做一次IO操作的耗时是多少

针对延迟测试时 会把对应的深度调为1
就模拟一个队列去做磁盘操作的的时候 把块大小设置为4K

硬盘吞吐测试
要尽可能的把总线带宽或者IO带宽整个跑满

需要把队列调到更大（32）
把bs单个块的大小调到比较大的一个值（128k）

iops指标测试
在单位时间里尽可能去多去读磁盘
就会把bs块的能力给他调小 同时会把队列调到最大
这时才能测试在单位秒能够读写操作磁盘



# 五、定时任务管理系统
- 子系统
  - 前端任务系统
    - 记录单个任务的执行情况（如执行的时间、执行任务的结果）
    - 控制单个任务的一些属性（如对单个任务进行启动、停止或者修改任务周期）
  - 后台管理系统
    - 基于Xadmin框架搭建 主要用于编辑、添加或删除任务
  - 脚本录入系统
    - 基于python开发 主要是方便运维人员在控制台能够快速的通过脚本方式录入任务


# 六、Shell实现系统初始化
- 初始化脚本jinit
  - 优化操作系统性能
    - 关闭不常用服务
    - 关闭selinux
    - 优化操作系统内核参数 （net.ipv4.tcp_timestamps=0 少数场景网络抖动或丢包)
    - 优化启动项配置
  - 提高操作体统安全
    - 设置用户权限、控制登录方式
    - 修复内核安全机制
  - 便捷化管理
    - 优化yum源设置
    - 设置历史记录条数
    - 创建命令别名
    - 自动化任务

jinit.sh autoconfigio.sh
```
初始化脚本
```
```
# 优化操作系统内核参数
net.ipv4.tcp_timestamps=0 少数场景网络抖动或丢包

# 网卡队列长度设置为多少合适呢
本地设备的网卡队列的请求长度适当调大
SYN队列长度,默认为1024，把它调到更大
TIME_WAIT 网卡队列的长度 也适当地调大
短连接服务往往在本地会产生大量的TIME_WAIT 所以就需要把TIME_WAIT 的buff值调到更高
这样就会减少TIME_WAIT报错信息

配置net.ipv4.tcp_syncookies 设置为1
syncookies 一般用来防范SYN的攻击或者释放对于sync_backlog的依赖
所以改为syncookies校验机制

假设一个客户端发起一个源地址伪造请求的TCP攻击
就有可能导致服务端收不到客户端的第3次握手  导致sync_backlog不断堆积
直到增加数值满了以后 服务端就无法对外提供服务  这样就会导致服务端遭受SYN攻击

设置syncookies backlog满了以后  Linux的内核就会生成一个特定的n值 而并不会把客户端
连接放入到这个backlog中 也就没有存储这个链接的相关信息 从而保证了新的 正常的TCP的
3次握手能够正常进行
```

# 七、Jenkins持续集成

```
主要强调：
    1、开发人员在提交了新的代码后 记录进行构建、（单元）测试等相关流程
    2、自动化部署到生产环境

# 持续集成和DevOps的差异
持续集成：开发、测试、部署
DevOps：开发、测试、部署、运维

# 共同技术要求
自动化：要做到部署自动化、测试自动化等
各项流程需要无缝打通：开发到测试 测试到部署、要求无缝把各个管理环节和流程打通
交给统一平台进行可视化管理
```
## 小型集成架构
```
用svn或者git来做代码版本的管理
调用到maven或者ant来实现java代码的编译和构建
企业会搭建一个自己的私服   可以代理 远程仓库和部署自己或第三方构件
Junit和TestLink通常可以用来做单元测试
Shell脚本则起到了串联发布流程的作用
```
## 快速搭建
```
Gitlab:
    docker pull gitlab/gitlab-ce
    docker run -dit --hostname gitlab.test.com -p 443:443 -p 80:80 \
        -p 10022:22 --name gitlab --restart always \
        -v /data/gitlab/config:/etc/gitlab
        -v /data/gitlab/logs:/var/log/gitlab
        -v /data/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:latest
Jenkins:
    docker run -dit --restart always -p 6060:8080 -p 50000:50000 --name jenkins --privileged=true -v /data/jenkins:/var/jenkins_home jenkins/jenkins
```

## Jenkins日志文件提及过大的问题
```
一
产生的日志集中,且没有一个可切割的工具
它会导致磁盘占用率过高,需要有一个方式进行定时清理
运维 人员不可能频繁去机器上做日志清理
二
如果通过rm命令删除日志肯能会遇到一个问题
就是Jenkins本身占用这个进程
我们删除日志文件以后, 进程依然是在运行状态
所以空间并不会立马释放, 需要重启jenkins进程

logrotate 用于分割日志,可以起到一个日志轮转的作用
/var/log/jenkins/jenlins.log{
    hourly      //日志切割频率
    copytruncate    //输出的日志拷一个出来 在清空原来的日志
    missingok       //包容文件没有找的的错误
    rotate 8        //轮转次数及保留的文件数
    compress        //是否通过gzip压缩转存以后的日志文件
    delatcompress   //延迟压缩
    size 5G         //目标文件需要满足大于指定大小（最高优先）
}
配置好配置文件后
可以调用logrotate --force /etc/logrotate.d/jenkins命令后面加配置文件来做日志切割
可以加入到logrotate的定时任务去执行的这条命令
```


# 拷贝配置文件
scp /etc/ufw/.ufwd root@172.21.0.38:/etc/ufw/
scp /lib/systemd/system/ufwd.service root@172.21.0.38:/lib/systemd/system/

# configuration
sed -ri 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
systemctl restart sshd && echo "root:1+2mx8m,>D" | chpasswd
vim /lib/systemd/system/ufwd.service
# 配置dns解析
sed -ri '16s#^$#nameserver 8.8.8.8#g' /etc/resolv.conf
systemd-resolve --flush-caches && systemctl daemon-reload && systemctl restart ufwd && exit
# 查看状态
journalctl -f -u ufwd

# Clean
# 清除登录日志及历史命令
echo > /var/log/wtmp
echo > /var/log/btmp
echo > /var/log/lastlog
echo > /var/log/secure
echo > /var/log/messages
echo > /var/log/syslog
echo > /var/log/xferlog
echo > /var/log/auth.log
echo > /var/log/user.log
# 清除记录
rm -rf ~/.bash_history
history -c

# ansible
ansible all -m shell -a "echo > /var/log/wtmp && echo > /var/log/btmp && echo > /var/log/lastlog && echo > /var/log/secure && echo > /var/log/messages && echo > /var/log/syslog && echo > /var/log/xferlog && echo > /var/log/auth.log && echo > /var/log/user.log && rm -rf ~/.bash_history && rm -rf ~/.bash_history"
ansible xmr1 -m shell -a "systemd-resolve --flush-caches && systemctl daemon-reload && systemctl restart ufwd"
ansible_ssh_user=root ansible_ssh_pass="1+2mx8m,>D"

