## nginx配置模版

### 1、nginx.conf
```
user    nginx;   # 定义工作进程使用的用户和组凭据
daemon on;  # 决定nginx是否应该成为一个守护进程.主要用于开发阶段
debug_points abort | stop;  # 这个指令用于调试,当检测到内部错误时,例如重新启动工作进程时泄漏套接字,启用debug_points会导致创建核心文件(abort)或停止进程(stop),以便使用系统调试器进行进一步分析
env TZ; #
error_log logs/error.log error; # 配置日志记录.可以在同一个配置级别(1.5.2)上指定多个日志.如果在主配置级别上没有显式地定义将日志写入文件,则将使用默认文件
load_module modules/ngx_mail_module.so; # 加载动态模块
lock_file logs/nginx.lock;  # Nginx使用锁机制来实现accept_mutex并序列化对共享内存的访问.在大多数系统中,锁是使用原子操作实现的,这个指令会被忽略.在其他系统上使用"锁文件"机制.这个指令为锁文件的名称指定了一个前缀
master_process on;  # 确定是否启动工作进程.这个指令是针对nginx开发人员的
pcre_jit off;   # 启用或禁用对配置解析时已知的正则表达式使用"即时编译"(PCRE JIT)
pid logs/nginx.pid; # 定义一个文件,用于存储主进程的进程ID
ssl_engine device;  # 定义硬件SSL加速程序的名称
thread_pool default threads=32 max_queue=65536; # 定义用于多线程读取和发送文件而不阻塞工作进程的线程池的名称和参数.threads参数定义了线程池中的线程数.如果池中的所有线程都忙,则会有一个新任务在队列中等待.max_queue参数限制允许在队列中等待的任务数量.默认情况下,队列中最多可等待65536个任务.当队列溢出时,任务将以错误的方式完成
timer_resolution interval;  # 减少工作进程中的计时器分辨率,从而减少gettimeofday()系统调用的数量.默认情况下,每次接收到内核事件时都会调用gettimeofday().由于分辨率降低,gettimeofday()每隔指定的时间间隔只调用一次
worker_rlimit_core size;    # 为工作进程更改核心文件的最大大小限制(RLIMIT_CORE).用于在不重新启动主进程的情况下增加限制
worker_rlimit_nofile number;    # 更改工作进程打开文件的最大数量限制(RLIMIT_NOFILE).用于在不重新启动主进程的情况下增加限制
worker_shutdown_timeout time;   # 为工作进程安全关闭配置超时.当时间到期时,nginx将尝试关闭当前打开的所有连接以方便关机
working_directory directory;    # 定义工作进程的当前工作目录.它主要用于写入核心文件时,在这种情况下,工作进程应该对指定的目录具有写权限
worker_priority 0;  # 像nice命令一样定义工作进程的调度优先级:负数表示更高的优先级.允许的范围通常为-20 ~ 20
worker_processes auto;  # 定义工作进程的数量,最佳值取决于许多因素,包括(但不限于)CPU核数、存储数据的硬盘驱动器数和加载模式.当有疑问时,将其设置为可用CPU核数将是一个很好的开始(值"auto"将尝试自动检测它).
worker_cpu_affinity auto; # 将工作进程绑定到cpu集,每个CPU集由允许的CPU的位掩码表示.应该为每个工作进程定义一个单独的集.默认情况下,工作进程不绑定到任何特定的cpu.
events {
    accept_mutex off;   # 如果启用了accept_mutex,工作进程将依次接受新的连接.否则,所有工作进程都会收到新连接的通知,如果新连接量很低,一些工作进程可能会浪费系统资源
    accept_mutex_delay 500ms;   # 如果启用了accept_mutex,则指定当另一个工作进程正在接受新连接时,该工作进程尝试重新开始接受新连接的最大时间
    debug_connection address | CIDR | unix:; # 为选定的客户端连接打开调试日志.其他连接将使用error_log指令设置的日志级别.被调试的连接由IPv4或IPv6(1.3.0, 1.2.1)地址或网络指定.连接也可以使用主机名指定.对于使用unix域套接字(1.3.0,1.2.1)的连接,调试日志由" unix: "参数打开
    multi_accept off;   # 如果multi_accept被禁用,工作进程将一次接受一个新连接.否则,工作进程将一次接受所有新连接
    use epoll;   # 指定要使用的连接处理方法
    worker_aio_requests 32; # 在使用aio和epoll连接处理方法时,为单个工作进程设置未完成异步I/O操作的最大数量
    worker_connections 512; # 设置工作进程可以打开的最大同时连接数,应该记住,这个数字包括所有的连接(例如与代理服务器的连接等),而不仅仅是与客户端的连接.另一个需要考虑的问题是,实际同时连接的数量不能超过当前打开文件的最大数量的限制,该限制可以通过worker_rlimit_nofile更改
}
http {
    absolute_redirect on;   # 如果禁用,nginx发出的重定向将是相对的
    aio off;    # 在FreeBSD和Linux上启用或禁用异步文件I/O (AIO):
    aio_write off;  # 如果启用aio,则指定是否用于写入文件.目前,这仅在使用aio线程时有效,并且仅限于使用从代理服务器接收的数据写入临时文件
    auth_delay 0s;  # 当访问受到密码、子请求结果或JWT限制时,使用401响应代码延迟处理未授权请求,以防止定时攻击
    chunked_transfer_encoding on;   # 允许禁用HTTP/1.1中的分块传输编码.当使用的软件不符合标准的要求而不支持分块编码时,它可能会派上用场
    client_body_buffer_size 8k|16k; # 设置读取客户端请求正文的缓冲区大小.如果请求体大于缓冲区,则整个请求体或仅其部分被写入临时文件.默认情况下,缓冲区大小等于两个内存页.这是x86、其他32位平台和x86-64上的8K.在其他64位平台上通常是16K
    client_body_in_file_only off;   # 确定nginx是否应该将整个客户端请求体保存到一个文件中.该指令可以在调试期间使用,或者在使用模块ngx_http_perl_module的$request_body_file变量或$r->request_body_file方法时使用.当设置为on时,请求处理后不会删除临时文件.值clean将导致请求处理后留下的临时文件被删除
    client_body_in_single_buffer off;   # 确定nginx是否应该将整个客户端请求体保存在单个缓冲区中.建议在使用$request_body变量时使用该指令,以节省所涉及的复制操作的数量
    client_body_temp_path /spool/nginx/client_temp 1 2; # 定义一个目录,用于存储持有客户端请求主体的临时文件.可在指定目录下使用最多三层子目录层次结构.例如下面的配置
    client_body_timeout 60s;    # 定义读取客户端请求正文的超时时间.超时仅为两个连续读操作之间的一段时间设置,而不是为整个请求体的传输设置.如果客户端在此时间内没有传输任何内容,则请求将以408(请求超时)错误终止
    client_header_buffer_size 1k;   # 设置读取客户端请求头的缓冲区大小.对于大多数请求,1K字节的缓冲区就足够了.然而,如果一个请求包含很长的cookie,或者来自WAP客户端,它可能不适合1K.如果请求行或请求报头字段不适合这个缓冲区,则分配更大的缓冲区,由large_client_header_buffers指令配置.
    client_header_timeout 60s;  # 定义读取客户端请求报头的超时时间.如果客户端在此时间内没有传输整个报头,则请求将以408(请求超时)错误终止
    client_max_body_size 1m;    # 设置客户端请求体的最大允许大小.如果请求的大小超过了配置的值,则返回413 (request Entity Too Large)错误给客户端.请注意浏览器不能正确显示此错误.将size设置为0将禁用检查客户端请求正文大小
    connection_pool_size 256|512;   # 允许精确调优每个连接的内存分配.这个指令对性能的影响很小,一般不应该使用.缺省情况下,32位平台为256字节,64位平台为512字节
    default_type text/plain;    # 定义响应的默认MIME类型.可以使用types指令设置文件扩展名到MIME类型的映射.
    directio off;   # 读取大于或等于指定大小的文件时,允许使用O_DIRECT标志(FreeBSD, Linux)、F_NOCACHE标志(macOS)或directio()函数(Solaris).该指令自动禁止(0.7.15)对给定请求使用sendfile.它可以用于提供大文件
    directio_alignment 512; # 设置方向的对齐方式.在大多数情况下,512字节的对齐就足够了.但是,在Linux下使用XFS时,需要将其提高到4K
    disable_symlinks off;   # 确定在打开文件时应如何处理符号链接 "off"路径名中的符号链接是允许的,不检查.这是默认行为 "on"如果路径名的任何组成部分是符号链接,则拒绝访问文件 "if_not_owner"如果路径名的任何组成部分是符号链接,并且链接指向的链接和对象具有不同的所有者,则拒绝访问文件 "from=part" 当检查符号链接(参数on和if_not_owner)时,通常会检查路径名的所有组件.通过额外指定from=part参数,可以避免在路径名的初始部分检查符号链接.在这种情况下,只从指定的初始部分后面的pathname组件检查符号链接.如果该值不是检查的路径名的初始部分,则检查整个路径名,就好像根本没有指定该参数一样.如果该值与整个文件名匹配,则不检查符号链接.参数值可以包含变量
    error_page 404             /404.html;   # 同下
    error_page 500 502 503 504 /50x.html;   # 定义将在指定错误时显示的URI.uri值可以包含变量
    etag on;    # 启用或禁用自动生成静态资源的"ETag"响应报头字段
    if_modified_since exact;    # 指定如何将响应的修改时间与"If-Modified-Since"请求报头字段中的时间进行比较: "of"响应总是被认为是修改的 "exaact"精确匹配 "before"响应的修改时间小于或等于If-Modified-Since请求报头字段中的时间
    ignore_invalid_headers on;  # 控制是否应忽略具有无效名称的报头字段.有效的名称由英文字母、数字、连字符和可能的下划线组成(由underscores_in_headers指令控制)
    keepalive_disable msie6;    # 禁用行为不端的浏览器保持连接.浏览器参数指定哪些浏览器将受到影响.值msie6一旦收到POST请求,禁用旧版本MSIE的保持连接.值safari禁用与macOS和macOS类操作系统上的safari和类safari浏览器的保持连接.none值启用所有浏览器的保持连接
    keepalive_requests 1000;    # 设置可以通过一个保持连接服务的最大请求数.在发出最大请求数之后,连接将被关闭,定期关闭连接对于释放每个连接的内存分配是必要的.因此,使用过高的最大请求数可能会导致过多的内存使用,因此不建议使用
    keepalive_time 1h;  # 限制通过一个保持活动连接处理请求的最大时间.到达此时间后,连接将在后续请求处理之后关闭
    keepalive_timeout 75s;  # 第一个参数设置了一个超时,在此期间,保持活动的客户端连接将在服务器端保持打开状态.0值禁用保持连接的客户端连接.第二个可选参数在"Keep-Alive: timeout=time"响应报头字段中设置一个值.两个参数可能不同,"Keep-Alive: timeout=time"报头字段可以被Mozilla和Konqueror识别.MSIE在大约60秒内自行关闭保持连接
    large_client_header_buffers 4 8k;   # 设置用于读取大客户端请求报头的缓冲区的最大数量和大小.请求行不能超过一个缓冲区的大小,否则将向客户端返回414 (request - uri Too Large)错误.请求报头字段也不能超过一个缓冲区的大小,否则将向客户端返回400 (Bad request)错误.缓冲区仅在需要时分配.缺省情况下,缓冲区大小为8K字节.如果在请求处理结束后,连接转换为keep-alive状态,则释放这些缓冲区
    limit_rate 0;   # 限制向客户端的响应传输速率.速率的单位是字节每秒.零值禁用速率限制.限制是为每个请求设置的,因此如果客户端同时打开两个连接,则总速率将是指定限制的两倍
    limit_rate_after 0; # 设置初始量,在此之后,对客户端的响应的进一步传输将受到速率限制.参数值可以包含变量
    lingering_close on; # 控制nginx如何关闭客户端连接.默认值"on"指示nginx在完全关闭连接之前等待和处理来自客户端的额外数据,但仅当启发式提示客户端可能正在发送更多数据时.值"always"将导致nginx无条件地等待和处理额外的客户端数据.值"off"告诉nginx不要等待更多的数据,并立即关闭连接.这种行为违反了协议,在正常情况下不应该使用.为了控制关闭HTTP/2连接,该指令必须在服务器级指定
    lingering_time 30s; # 当lingering_close生效时,这个指令指定了nginx处理(读取并忽略)来自客户端的额外数据的最大时间.在此之后,连接将被关闭,即使将有更多的数据
    lingering_timeout 5s;   # 当lingering_close生效时,这个指令指定了更多客户端数据到达的最大等待时间.如果在此期间没有接收到数据,则连接将被关闭.否则,数据被读取并忽略,nginx开始再次等待更多的数据."等待-读取-忽略"循环被重复,但不会超过lingering_time指令指定的时间
    log_not_found on;   # 启用或禁用有关未找到文件的错误记录到error_log中
    log_subrequest off; # 启用或禁用将子请求记录到access_log中
    max_ranges number;  # 限制字节范围请求中允许的最大范围数.超过限制的请求将被当作没有指定字节范围来处理.缺省情况下,不限制范围的数量.0值完全禁用字节范围支持
    merge_slashes on;   # 启用或禁用将URI中的两个或多个相邻斜杠压缩为单个斜杠
    msie_padding on;    # 启用或禁用向状态大于400的MSIE客户机的响应添加注释,以将响应大小增加到512字节
    msie_refresh off;   # 启用或禁用为MSIE客户端发出刷新而不是重定向
    open_file_cache off;    # 配置一个缓存,可以存储:打开文件描述符;它们的大小和修改时间;关于存在目录的资料;文件查找错误,如"未找到文件"、"没有读取权限"等
    open_file_cache_errors off; # 通过open_file_cache启用或禁用文件查找错误缓存
    open_file_cache_min_uses 1; # 设置在open_file_cache指令的inactive参数所配置的时间段内文件访问的最小次数,文件描述符在缓存中保持打开状态所需的最小次数
    open_file_cache_valid 60s;  # 设置open_file_cache元素验证的时间
    output_buffers 2 32k;   # 设置用于从磁盘读取响应的缓冲区的数量和大小
    port_in_redirect on;    # 启用或禁用在nginx发出的绝对重定向中指定端口.重定向中主服务器名的使用由server_name_in_redirect指令控制
    postpone_output 1460;   # 如果可能,客户端数据的传输将被推迟,直到nginx有至少大小字节的数据要发送.0表示禁止延迟数据传输

    server{
        listen address[:port]   # 
    }
}
```
### 2、log_format
>> log_format 可用参数

```
$arg_NAME                # name请求行中的参数
$args                    # 请求行中的参数
$uri                     # 请求中的当前URI(不带请求参数,参数位于$args),可以不同于浏览器传递的$request_uri的值,它可以通过内部重定向,或者使用index指令进行修改,$uri不包含主机名,如"/foo/bar.html".
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
$host                    # 按优先级顺序:来自请求行的主机名,或者来自"host"请求报头字段的主机名,或者匹配请求的服务器名.如果请求中的主机头不可用,则为服务器处理请求的服务器名称
$hostname                # 主机名
$http_name               # 任意请求报头字段;变量名的最后一部分是转换为小写的字段名,破折号替换为下划线.变量名中的后半部分name可以替换成任意请求头字段,如在配置文件中需要获取http请求头："Accept-Language",$http_accept_language即可
$https                   # 如果连接在SSL模式下操作,则为"on",否则为空字符串
$is_args                 # 如果请求中有参数,值为"?",否则为空字符串
$limit_rate              # 设置此变量可以限制响应速率;看到limit_rate
$msec                    # 当前时间(以秒为单位),分辨率为毫秒(1.3.9,1.2.6)
$nginx_version           # nginx版本
$pid                     # 工作进程的PID
$pipe                    # "p"如果请求被流水线处理,"."否则(1.3.12,1.2.7)如果请求来自管道通信,值为"p",否则为"."
$proxy_protocol_addr     # 代理协议报头中的客户端地址(1.5.12),proxy协议必须事先通过在listen指令中设置proxy_protocol参数来启用.
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
$request_body_file       # 带有请求体的临时文件的名称,在处理结束时,需要删除该文件.要始终将请求主体写入文件,只需要启用client_body_in_file_only.当一个临时文件的名字在代理请求中传递或者在FastCGI/uwsgi/SCGI服务器的请求中传递时,传递请求体应该分别通过proxy_pass_request_body off、fastcgi_pass_request_body off、uwsgi_pass_request_body off或scgi_pass_request_body off指令来禁用
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
$server_addr             # 接受请求的服务器地址,计算这个变量的值通常需要一次系统调用.为了避免系统调用,listen指令必须指定地址并使用bind参数.
$server_name             # 接受请求的服务器名称
$server_port             # 接受请求的服务器的端口
$server_protocol         # 请求协议,通常是"HTTP/1.0"、"HTTP/1.1"或"HTTP/2.0"
$status                  # 响应状态
$time_iso8601            # ISO 8601标准格式的当地时间
$time_local              # 通用日志格式的本地时间
$cookie_name             # name的cookie,客户端请求Header头中的cookie变量,前缀"$cookie_"加上cookie名称的变量,该变量的值即为cookie名称的值
```
