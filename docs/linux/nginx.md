# Nginx配置

## 从源代码构建Nginx

使用configure命令配置构建,它定义了系统的各个方面，包括允许nginx用于连接处理的方法。最后，它会创建一个Makefile。

该configure命令支持以下参数：
```
--help 打印帮助信息
--prefix=path
定义保存服务器文件的目录,在nginx.conf配置文件中，配置设置的所有相对路径(库源路径除外)也将使用同一个目录。默认设置为/usr/local/nginx目录。
--sbin-path=path
设置nginx可执行文件的名称,此名称仅在安装期间使用。默认文件命名为prefix/sbin/nginx。--modules-path=path
定义将安装nginx动态模块的目录。默认情况下使用prefix/modules目录。
--conf-path=path
设置nginx.conf配置文件的名称。如果需要，nginx可以通过命令行参数-c file指定不同的配置文件启动。默认文件命名为prefix/conf/nginx.conf
--error-log-path=path
设置主要错误、警告和诊断文件的名称,安装后可以使用error_log指令在nginx.conf配置文件中更改文件名。默认情况下，该文件命名为prefix/logs/error.log
--pid-path=path
设置nginx的名称。用于存储主进程的进程ID的pid文件。安装后，可以使用pid指令在nginx.conf配置文件中更改文件名。默认情况下，该文件名为prefix/logs/nginx.pid
--lock-path=path
设置锁定文件名称的前缀,安装后，这个值可以在nginx.conf配置文件中使用lock_file指令更改。默认值是prefix/logs/nginx.lock
--user=name
设置将由工作进程使用其凭证的非特权用户的名称,安装后名称可以在nginx.conf配置文件中使用user指令更改。默认用户名是nobody。
--group=name
设置工作进程将使用其凭证的组的名称,安装后名称可以在nginx.conf配置文件中使用user指令更改。默认情况下，组名被设置为非特权用户的名称。
--build=name
设置一个可选的nginx构建名.
--builddir=path
设置构建目录。
--with-select_module
--without-select_module
启用或禁用构建允许服务器使用select()方法的模块。如果平台似乎不支持更合适的方法，如kqueue、epoll或/dev/poll，则自动构建此模块。
--with-poll_module
--without-poll_module
启用或禁用构建允许服务器使用poll()方法的模块。如果平台似乎不支持更合适的方法，如kqueue、epoll或/dev/poll，则自动构建此模块。
--with-threads
启用线程池的使用 。
--with-file-aio
允许在FreeBSD和Linux上使用异步文件I/O (AIO)。
--with-http_ssl_module
支持构建向HTTP服务器添加HTTPS协议支持的模块,默认情况下不构建此模块。构建和运行此模块需要OpenSSL库。
--with-http_v2_module
支持构建支持HTTP/2的模块。默认情况下不构建此模块。
--with-http_realip_module
启用构建ngx_http_realip_module 模块的功能，该 模块将客户端地址更改为在指定的标头字段中发送的地址。默认情况下未构建此模块。
--with-http_addition_module
允许构建ngx_http_addition_module 模块，该 模块在响应前后添加文本。默认情况下未构建此模块。
--with-http_xslt_module
--with-http_xslt_module=dynamic
支持构建ngx_http_xslt_module 模块，该 模块使用一个或多个XSLT样式表转换XML响应。默认情况下未构建此模块。该libxml2的和 的libxslt库需要构建和运行此模块。
--with-http_image_filter_module
--with-http_image_filter_module=dynamic
支持构建ngx_http_image_filter_module 模块，该 模块可以转换JPEG，GIF，PNG和WebP格式的图像。默认情况下未构建此模块。
--with-http_geoip_module
--with-http_geoip_module=dynamic
支持构建ngx_http_geoip_module 模块，该 模块根据客户端IP地址和预编译的MaxMind数据库创建变量 。默认情况下未构建此模块。
--with-http_sub_module
支持构建ngx_http_sub_module 模块，该 模块通过将一个指定的字符串替换为另一个指定的字符串来修改响应。默认情况下未构建此模块。
--with-http_dav_module
支持构建ngx_http_dav_module 模块，该 模块通过WebDAV协议提供文件管理自动化。默认情况下未构建此模块。
--with-http_flv_module
支持构建ngx_http_flv_module 模块，该 模块为Flash Video（FLV）文件提供伪流服务器端支持。默认情况下未构建此模块。
--with-http_mp4_module
支持构建ngx_http_mp4_module 模块，该 模块为MP4文件提供伪流服务器端支持。默认情况下未构建此模块。
--with-http_gunzip_module
支持为不支持“ gzip”编码方法的客户端构建ngx_http_gunzip_module 模块，该 模块使用“ Content-Encoding: gzip” 解压缩响应。默认情况下未构建此模块。
--with-http_gzip_static_module
支持构建ngx_http_gzip_static_module 模块，该 模块支持发送.gz扩展名为“ ”的预压缩文件，而不是常规文件。默认情况下未构建此模块。
--with-http_auth_request_module
允许构建ngx_http_auth_request_module 模块，该 模块基于子请求的结果实现客户端授权。默认情况下未构建此模块。
--with-http_random_index_module
支持构建ngx_http_random_index_module 模块，该 模块处理以斜杠（' /'）结尾的请求，并在目录中选择一个随机文件作为索引文件。默认情况下未构建此模块。
--with-http_secure_link_module
启用构建 ngx_http_secure_link_module 模块。默认情况下未构建此模块。
--with-http_degradation_module
启用构建 ngx_http_degradation_module模块。默认情况下未构建此模块。
--with-http_slice_module
支持构建ngx_http_slice_module 模块，该 模块将请求拆分为子请求，每个子请求返回一定范围的响应。该模块提供了更有效的大响应缓存。默认情况下未构建此模块。
--with-http_stub_status_module
支持构建ngx_http_stub_status_module 模块，该 模块提供对基本状态信息的访问。默认情况下未构建此模块。
--without-http_charset_module
禁用构建ngx_http_charset_module 模块，该 模块将指定的字符集添加到“ Content-Type”响应头字段中，并且可以将数据从一个字符集转换为另一个字符集。
--without-http_gzip_module
禁用构建可压缩 HTTP服务器响应的模块。zlib库是构建和运行此模块所必需的。
--without-http_ssi_module
禁用构建 处理通过SSI（服务器端包含）命令的 ngx_http_ssi_module模块的响应。
--without-http_userid_module
禁用构建ngx_http_userid_module 模块，该 模块设置适用于客户端标识的cookie。
--without-http_access_module
禁用构建ngx_http_access_module 模块，该 模块允许限制对某些客户端地址的访问。
--without-http_auth_basic_module
禁用构建ngx_http_auth_basic_module 模块，该 模块允许通过使用“ HTTP基本身份验证”协议验证用户名和密码来限制对资源的访问。
--without-http_mirror_module
禁用构建ngx_http_mirror_module 模块，该 模块通过创建后台镜像子请求来实现原始请求的镜像。
--without-http_autoindex_module
禁用构建 ngx_http_autoindex_module 模块，以处理以斜杠（' /'）结尾的请求，并在ngx_http_index_module模块找不到索引文件的情况下生成目录列表 。
--without-http_geo_module
禁用构建ngx_http_geo_module 模块，该 模块创建的变量值取决于客户端IP地址。
--without-http_map_module
禁用构建ngx_http_map_module 模块，该 模块创建的变量值取决于其他变量的值。
--without-http_split_clients_module
禁用构建ngx_http_split_clients_module 模块，该 模块创建用于A / B测试的变量。
--without-http_referer_module
禁用构建ngx_http_referer_module 模块，该 模块可以阻止对“ Referer”标头字段中具有无效值的请求的站点访问。
--without-http_rewrite_module
禁用构建允许HTTP服务器 重定向请求并更改请求URI的模块。构建和运行此模块需要PCRE库。
--without-http_proxy_module
禁用构建HTTP服务器 代理模块。
--without-http_fastcgi_module
禁用构建 将请求传递到FastCGI服务器的 ngx_http_fastcgi_module模块。
--without-http_uwsgi_module
禁用构建 将请求传递到uwsgi服务器的 ngx_http_uwsgi_module模块。
--without-http_scgi_module
禁用构建 将请求传递到SCGI服务器的 ngx_http_scgi_module模块。
--without-http_grpc_module
禁用构建 将请求传递到gRPC服务器的 ngx_http_grpc_module模块。
--without-http_memcached_module
禁用构建ngx_http_memcached_module 模块，该 模块从Memcached服务器获取响应。
--without-http_limit_conn_module
禁用构建ngx_http_limit_conn_module 模块，该 模块限制每个键的连接数，例如，单个IP地址的连接数。
--without-http_limit_req_module
禁用构建ngx_http_limit_req_module 模块，该 模块限制每个密钥的请求处理速率，例如，来自单个IP地址的请求的处理速率。
--without-http_empty_gif_module
禁用构建发出单像素透明GIF的模块 。
--without-http_browser_module
禁用构建ngx_http_browser_module 模块，该 模块创建的变量值取决于“ User-Agent”请求标头字段的值。
--without-http_upstream_hash_module
禁用构建实现哈希 负载平衡方法的模块 。
--without-http_upstream_ip_hash_module
禁用构建实现ip_hash 负载平衡方法的模块 。
--without-http_upstream_least_conn_module
禁用构建实现了minimum_conn 负载平衡方法的模块 。
--without-http_upstream_keepalive_module
禁用构建一个模块，该模块提供 对到上游服务器的连接的缓存。
--without-http_upstream_zone_module
禁用构建模块，该模块可以将上游组的运行时状态存储在共享内存 区域中。
--with-http_perl_module
--with-http_perl_module=dynamic
支持构建 嵌入式Perl模块。默认情况下未构建此模块。
--with-perl_modules_path=path
定义一个目录，该目录将保留Perl模块。
--with-perl=path
设置Perl二进制文件的名称。
--http-log-path=path
设置HTTP服务器的主请求日志文件的名称。安装后，可以始终nginx.conf使用access_log伪指令在配置文件中 更改文件名 。默认情况下，文件名为 prefix/logs/access.log。
--http-client-body-temp-path=path
定义用于存储包含客户端请求正文的临时文件的目录。安装后，可以始终nginx.conf使用client_body_temp_path 指令在配置文件中 更改目录 。默认情况下，目录名为 prefix/client_body_temp。
--http-proxy-temp-path=path
定义一个目录，用于存储带有从代理服务器接收到的数据的临时文件。安装后，可以始终nginx.conf使用proxy_temp_path 指令在配置文件中 更改目录 。默认情况下，目录名为 prefix/proxy_temp。
--http-fastcgi-temp-path=path
定义一个目录，用于存储包含从FastCGI服务器接收到的数据的临时文件。安装后，可以始终nginx.conf使用fastcgi_temp_path 指令在配置文件中 更改目录 。默认情况下，目录名为 prefix/fastcgi_temp。
--http-uwsgi-temp-path=path
定义一个目录，用于存储包含从uwsgi服务器接收到的数据的临时文件。安装后，可以始终nginx.conf使用uwsgi_temp_path 指令在配置文件中 更改目录 。默认情况下，目录名为 prefix/uwsgi_temp。
--http-scgi-temp-path=path
定义一个目录，用于存储包含从SCGI服务器接收到的数据的临时文件。安装后，可以始终nginx.conf使用scgi_temp_path 指令在配置文件中 更改目录 。默认情况下，目录名为 prefix/scgi_temp。
--without-http
禁用HTTP服务器。
--without-http-cache
禁用HTTP缓存。
--with-mail
--with-mail=dynamic
启用POP3 / IMAP4 / SMTP 邮件代理服务器。
--with-mail_ssl_module
启用构建将 SSL / TLS协议支持添加 到邮件代理服务器的模块的功能。默认情况下未构建此模块。需要OpenSSL库来构建和运行此模块。
--without-mail_pop3_module
在邮件代理服务器中 禁用POP3协议。
--without-mail_imap_module
在邮件代理服务器中 禁用IMAP协议。
--without-mail_smtp_module
在邮件代理服务器中 禁用SMTP协议。
--with-stream
--with-stream=dynamic
支持构建 用于通用TCP / UDP代理和负载平衡的 流模块。默认情况下未构建此模块。
--with-stream_ssl_module
支持构建一个模块，该模块 向流模块添加 SSL / TLS协议支持。默认情况下未构建此模块。需要OpenSSL库来构建和运行此模块。
--with-stream_realip_module
启用构建ngx_stream_realip_module 模块的功能，该 模块将客户端地址更改为PROXY协议标头中发送的地址。默认情况下未构建此模块。
--with-stream_geoip_module
--with-stream_geoip_module=dynamic
支持构建ngx_stream_geoip_module 模块，该 模块根据客户端IP地址和预编译的MaxMind数据库创建变量 。默认情况下未构建此模块。
--with-stream_ssl_preread_module
支持构建ngx_stream_ssl_preread_module 模块，该 模块允许从ClientHello 消息中提取信息， 而无需终止SSL / TLS。默认情况下未构建此模块。
--without-stream_limit_conn_module
禁用构建ngx_stream_limit_conn_module 模块，该 模块限制每个键的连接数，例如，单个IP地址的连接数。
--without-stream_access_module
禁用构建ngx_stream_access_module 模块，该 模块允许限制对某些客户端地址的访问。
--without-stream_geo_module
禁用构建ngx_stream_geo_module 模块，该 模块创建的变量的值取决于客户端IP地址。
--without-stream_map_module
禁用构建ngx_stream_map_module 模块，该 模块创建的变量值取决于其他变量的值。
--without-stream_split_clients_module
禁用构建ngx_stream_split_clients_module 模块，该 模块创建用于A / B测试的变量。
--without-stream_return_module
禁用构建ngx_stream_return_module 模块，该 模块向客户端发送一些指定的值，然后关闭连接。
--without-stream_upstream_hash_module
禁用构建实现哈希 负载平衡方法的模块 。
--without-stream_upstream_least_conn_module
禁用构建实现了minimum_conn 负载平衡方法的模块 。
--without-stream_upstream_zone_module
禁用构建模块，该模块可以将上游组的运行时状态存储在共享内存 区域中。
--with-google_perftools_module
允许构建ngx_google_perftools_module 模块，以使用Google Performance Tools对 Nginx工作进程进行 性能分析。该模块适用于Nginx开发人员，默认情况下未构建。
--with-cpp_test_module
启用构建 ngx_cpp_test_module模块。
--add-module=path
启用外部模块。
--add-dynamic-module=path
启用外部动态模块。
--with-compat
启用动态模块兼容性。
--with-cc=path
设置C编译器的名称。
--with-cpp=path
设置C预处理器的名称。
--with-cc-opt=parameters
设置将添加到CFLAGS变量的其他参数。在FreeBSD下使用系统PCRE库时， --with-cc-opt="-I /usr/local/include" 应指定。如果select()需要增加支持的文件数量，也可以在此处指定，例如： --with-cc-opt="-D FD_SETSIZE=2048"。
--with-ld-opt=parameters
设置在链接期间将使用的其他参数。在FreeBSD下使用系统PCRE库时， --with-ld-opt="-L /usr/local/lib" 应指定。
--with-cpu-opt=cpu
每个指定的CPU能够使建筑： pentium，pentiumpro， pentium3，pentium4， athlon，opteron， sparc32，sparc64， ppc64。
--without-pcre
禁用PCRE库的使用。
--with-pcre
强制使用PCRE库。
--with-pcre=path
设置PCRE库源的路径。需要从PCRE站点下载并分发库分发（版本4.4 — 8.43） 。其余的由nginx的./configure和完成 make。该库对于location指令中的正则表达式支持和 ngx_http_rewrite_module 模块是必需的 。
--with-pcre-opt=parameters
为PCRE设置其他构建选项。
--with-pcre-jit
使用“及时编译”支持（1.1.12，pcre_jit指令）构建PCRE库 。
--with-zlib=path
设置zlib库源的路径。需要从zlib站点下载库发行版（版本1.1.3-1.2.11） 并解压缩。其余的由nginx的./configure和完成 make。ngx_http_gzip_module模块需要该库 。
--with-zlib-opt=parameters
为zlib设置其他构建选项。
--with-zlib-asm=cpu
使得能够使用指定的CPU中的一个优化的zlib汇编源程序： pentium，pentiumpro。
--with-libatomic
强制使用libatomic_ops库。
--with-libatomic=path
设置libatomic_ops库源的路径。
--with-openssl=path
设置OpenSSL库源的路径。
--with-openssl-opt=parameters
为OpenSSL设置其他构建选项。
--with-debug
启用调试日志。


```

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


