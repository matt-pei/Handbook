## nginx配置模版

### 1、nginx.conf
```
user    nginx;
error_log logs/error.log error;
worker_rlimit_core 65535;
worker_rlimit_nofile 65535;
worker_priority 0;
worker_processes auto;
worker_cpu_affinity auto;
events {
    accept_mutex off;
    multi_accept off;
    use epoll;
    worker_connections 512;
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
