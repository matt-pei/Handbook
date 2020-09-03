# Linux kernel

## ulimit
ulimit是一种Linux系统的内键功能,它具有一套参数集,用于为由它生成的shell进程及其子进程的资源使用设置限制。
### 设置格式
```
<domain>        <type>  <item>  <value>
```

```
<domain>:
    - a user name
    - a group name, with @group syntax
    - the wildcard *, for default entry
    - the wildcard %, can be also used with %group syntax,for maxlogin limit
```

```
<type> can have the two values:
    - "soft" for enforcing the soft limits
    - "hard" for enforcing hard limits
```

```
<item> can be one of the following:
    - core - limits the core file size (KB)
    - data - max data size (KB)
    - fsize - maximum filesize (KB)
    - memlock - max locked-in-memory address space (KB)
    - nofile - max number of open file descriptors
    - rss - max resident set size (KB)
    - stack - max stack size (KB)
    - cpu - max CPU time (MIN)
    - nproc - max number of processes
    - as - address space limit (KB)
    - maxlogins - max number of logins for this user
    - maxsyslogins - max number of logins on the system
    - priority - the priority to run user process with
    - locks - max number of file locks the user can hold
    - sigpending - max number of pending signals
    - msgqueue - max memory used by POSIX message queues (bytes)
    - nice - max nice priority allowed to raise to values: [-20, 19]
    - rtprio - max realtime priority
```

- core - limits the core file size (KB)
- data - max data size (KB)
- fsize - maximum filesize (KB)
- memlock - max locked-in-memory address space (KB)
- nofile - max number of open file descriptors
- rss - max resident set size (KB)
- stack - max stack size (KB)
- cpu - max CPU time (MIN)
- nproc - max number of processes
- as - address space limit (KB)
- maxlogins - max number of logins for this user
- maxsyslogins - max number of logins on the system
- priority - the priority to run user process with
- locks - max number of file locks the user can hold
- sigpending - max number of pending signals
- msgqueue - max memory used by POSIX message queues (bytes)
- nice - max nice priority allowed to raise to values: [-20, 19]
- rtprio - max realtime priority

