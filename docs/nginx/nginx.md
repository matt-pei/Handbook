## nginx配置模版

### 1、nginx.conf
```
user    nginx;   # 定义工作进程使用的用户和组凭据
daemon on;  # 决定nginx是否应该成为一个守护进程。主要用于开发阶段
debug_points abort | stop;  # 这个指令用于调试,当检测到内部错误时，例如重新启动工作进程时泄漏套接字，启用debug_points会导致创建核心文件(abort)或停止进程(stop)，以便使用系统调试器进行进一步分析
env TZ; #
error_log logs/error.log error; # 配置日志记录。可以在同一个配置级别(1.5.2)上指定多个日志。如果在主配置级别上没有显式地定义将日志写入文件，则将使用默认文件
worker_rlimit_core size;    # 为工作进程更改核心文件的最大大小限制(RLIMIT_CORE)。用于在不重新启动主进程的情况下增加限制
worker_rlimit_nofile number;    # 更改工作进程打开文件的最大数量限制(RLIMIT_NOFILE)。用于在不重新启动主进程的情况下增加限制
worker_shutdown_timeout time;   # 为工作进程安全关闭配置超时。当时间到期时，nginx将尝试关闭当前打开的所有连接以方便关机
working_directory directory;    # 定义工作进程的当前工作目录。它主要用于写入核心文件时，在这种情况下，工作进程应该对指定的目录具有写权限
worker_priority 0;  # 像nice命令一样定义工作进程的调度优先级:负数表示更高的优先级。允许的范围通常为-20 ~ 20
worker_processes auto;  # 定义工作进程的数量,最佳值取决于许多因素，包括(但不限于)CPU核数、存储数据的硬盘驱动器数和加载模式。当有疑问时，将其设置为可用CPU核数将是一个很好的开始(值“auto”将尝试自动检测它)。
worker_cpu_affinity auto; # 将工作进程绑定到cpu集,每个CPU集由允许的CPU的位掩码表示。应该为每个工作进程定义一个单独的集。默认情况下,工作进程不绑定到任何特定的cpu。
events {
    accept_mutex off;   # 如果启用了accept_mutex，工作进程将依次接受新的连接。否则，所有工作进程都会收到新连接的通知，如果新连接量很低，一些工作进程可能会浪费系统资源
    accept_mutex_delay 500ms;   # 如果启用了accept_mutex，则指定当另一个工作进程正在接受新连接时，该工作进程尝试重新开始接受新连接的最大时间
    debug_connection address | CIDR | unix:; # 为选定的客户端连接打开调试日志。其他连接将使用error_log指令设置的日志级别。被调试的连接由IPv4或IPv6(1.3.0, 1.2.1)地址或网络指定。连接也可以使用主机名指定。对于使用unix域套接字(1.3.0,1.2.1)的连接，调试日志由" unix: "参数打开
    multi_accept off;   # 如果multi_accept被禁用，工作进程将一次接受一个新连接。否则，工作进程将一次接受所有新连接
    use epoll;   # 指定要使用的连接处理方法
    worker_aio_requests 32; # 在使用aio和epoll连接处理方法时，为单个工作进程设置未完成异步I/O操作的最大数量
    worker_connections 512; # 设置工作进程可以打开的最大同时连接数,应该记住，这个数字包括所有的连接(例如与代理服务器的连接等)，而不仅仅是与客户端的连接。另一个需要考虑的问题是，实际同时连接的数量不能超过当前打开文件的最大数量的限制，该限制可以通过worker_rlimit_nofile更改
}
http {
    absolute_redirect on;   # 如果禁用，nginx发出的重定向将是相对的
    aio off;    # 在FreeBSD和Linux上启用或禁用异步文件I/O (AIO):
    aio_write off;  # 如果启用aio，则指定是否用于写入文件。目前，这仅在使用aio线程时有效，并且仅限于使用从代理服务器接收的数据写入临时文件
    auth_delay 0s;  # 当访问受到密码、子请求结果或JWT限制时，使用401响应代码延迟处理未授权请求，以防止定时攻击
    chunked_transfer_encoding on;   # 设置读取客户端请求正文的缓冲区大小。如果请求体大于缓冲区，则整个请求体或仅其部分被写入临时文件。默认情况下，缓冲区大小等于两个内存页。这是x86、其他32位平台和x86-64上的8K。在其他64位平台上通常是16K
}
```
### 2、log_format
>> log_format 可用参数

```
$arg_NAME                # name请求行中的参数
$args                    # 请求行中的参数
$uri                     # 请求中的当前URI(不带请求参数,参数位于$args),可以不同于浏览器传递的$request_uri的值,它可以通过内部重定向,或者使用index指令进行修改,$uri不包含主机名,如"/foo/bar.html"。
$binary_remote_addr      # 客户端地址二进制形式,值的长度总是4字节的IPv4地址或16字节的IPv6地址
$body_bytes_sent         #发送到客户端的字节数,不包括响应头;该变量与mod_log_config Apache模块的"%B"参数兼容
$bytes_sent              # 发送到客户端的字节数(1.3.8,1.2.5)
$connection              # TCP连接序号(1.3.8,1.2.5)
$connection_requests     # TCP当前通过连接发出的请求数(1.3.8,1.2.5)
$connection_time         # 以秒为单位的连接时间,分辨率为毫秒(1.19.10)
$content_length          # "Content-Length"请求报头字段
$content_type            # "Content-Type"请求报头字段
$cookie_name             # 名字cookie
$document_root           # 当前请求的/或别名指令的值
$document_uri            # 和$uri一样
$host                    # 按优先级顺序:来自请求行的主机名,或者来自"host"请求报头字段的主机名,或者匹配请求的服务器名。如果请求中的主机头不可用,则为服务器处理请求的服务器名称
$hostname                # 主机名
$http_name               # 任意请求报头字段;变量名的最后一部分是转换为小写的字段名,破折号替换为下划线。变量名中的后半部分name可以替换成任意请求头字段,如在配置文件中需要获取http请求头："Accept-Language",$http_accept_language即可
$https                   # 如果连接在SSL模式下操作,则为"on",否则为空字符串
$is_args                 # 如果请求中有参数,值为"?",否则为空字符串
$limit_rate              # 设置此变量可以限制响应速率;看到limit_rate
$msec                    # 当前时间(以秒为单位),分辨率为毫秒(1.3.9,1.2.6)
$nginx_version           # nginx版本
$pid                     # 工作进程的PID
$pipe                    # "p"如果请求被流水线处理,"."否则(1.3.12,1.2.7)如果请求来自管道通信,值为"p",否则为"."
$proxy_protocol_addr     # 代理协议报头中的客户端地址(1.5.12),proxy协议必须事先通过在listen指令中设置proxy_protocol参数来启用。
$proxy_protocol_port     # 来自PROXY协议头的客户端端口(1.11.0),proxy协议必须事先通过在listen指令中设置proxy_protocol参数来启用
$proxy_protocol_server_addr # 来自代理协议报头的服务器地址(1.17.6),proxy协议必须事先通过在listen指令中设置proxy_protocol参数来启用
$proxy_protocol_server_port # 来自proxy协议头的服务器端口(1.17.6),proxy协议必须事先通过在listen指令中设置proxy_protocol参数来启用
$query_string            # 和$args一样
$realpath_root           # 对应于当前请求的/或别名指令值的绝对路径名,所有符号链接都解析为真实路径
$remote_addr             # 客户端地址
$remote_port             # 客户端端口
$remote_user             # 身份验证提供的用户名
$request                 # 完整的原始请求行
$request_body            #请求体,当请求体被读入内存缓冲区时,该变量的值在proxy_pass、fastcgi_pass、uwsgi_pass和scgi_pass指令处理的位置中可用.
$request_body_file       # 带有请求体的临时文件的名称,在处理结束时,需要删除该文件。要始终将请求主体写入文件,只需要启用client_body_in_file_only。当一个临时文件的名字在代理请求中传递或者在FastCGI/uwsgi/SCGI服务器的请求中传递时,传递请求体应该分别通过proxy_pass_request_body off、fastcgi_pass_request_body off、uwsgi_pass_request_body off或scgi_pass_request_body off指令来禁用
$request_completion      # "OK"表示请求已完成,否则为空字符串
$request_filename        # 当前请求的文件路径,基于/或别名指令,以及请求URI
$request_id              # 由16个随机字节生成的唯一请求标识符,十六进制(1.11.0)
$request_length          # 请求长度(包括请求行、请求头和请求体)(1.3.12,1.2.7)
$request_method          # 请求方法,通常是"GET"或"POST"
$request_time            # 请求处理时间(以秒为单位),分辨率为毫秒(1.3.9,1.2.6);从客户端读取第一个字节开始的时间
$request_uri             # 完整的原始请求URI(带参数),这个变量等于包含一些客户端请求参数的原始URI,它无法修改,请查看$uri更改或重写URI,不包含主机名,例如："/cnphp/test.php?arg=freemouse"
$scheme                  # 请求方案,"http"或"https"
$sent_http_name          # 任意响应报头字段;变量名的最后一部分是转换为小写的字段名,破折号替换为下划线,变量名中的后半部分NAME可以替换成任意响应头字段,如需要设置响应头Content-length,$sent_http_content_length即可
$sent_trailer_name       # 在响应结束时发送的任意字段(1.13.2);变量名的最后一部分是转换为小写的字段名,破折号替换为下划线
$server_addr             # 接受请求的服务器地址,计算这个变量的值通常需要一次系统调用。为了避免系统调用,listen指令必须指定地址并使用bind参数.
$server_name             # 接受请求的服务器名称
$server_port             # 接受请求的服务器的端口
$server_protocol         # 请求协议,通常是"HTTP/1.0"、"HTTP/1.1"或"HTTP/2.0"
$status                  # 响应状态
$time_iso8601            # ISO 8601标准格式的当地时间
$time_local              # 通用日志格式的本地时间
$cookie_name             # name的cookie,客户端请求Header头中的cookie变量,前缀"$cookie_"加上cookie名称的变量,该变量的值即为cookie名称的值
```
