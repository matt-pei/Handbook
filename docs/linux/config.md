#

## 1、修改禁止普通用户切换root用户
### 1、修改/etc/pam.d/su配置
```
#打开这个配置文件，找到如下行，并将行首”#”去掉，保存文件
auth required pam_wheel.so use_uid
```

### 2、修改/etc/login.defs文件
```
#在文件末尾添加 SU_WHEEL_ONLY yes 保存文件
vi /etc/login.defs 
```

### 3、vim /etc/sudoers     添加
```
## Allow root to run any commands anywhere 
mccok  ALL=(ALL)       ALL,!/bin/su
```

## 2、使用cfssl自签证书
```
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o cfssl-certinfo
```


---

### 查看服务器资源
```
# 查看cpu物理个数
cat /proc/cpuinfo | grep 'phy' | sort | uniq
address sizes	: 46 bits physical, 48 bits virtual
physical id	: 0
physical id	: 1
```

```
# 查看单个cpu物理核数
cat /proc/cpuinfo | grep 'cores' | uniq
cpu cores	: 12
```

```
# 查看cpu总共逻辑核数
cat /proc/cpuinfo | grep 'processor' | wc -l
48
```

```
# 查看cpu型号
cat /proc/cpuinfo | sort | uniq | grep 'model'
model		: 85
model name	: Intel(R) Xeon(R) Silver 4214 CPU @ 2.20GHz
```

```
# 查看服务器品牌
grep 'DMI' /var/log/dmesg
[    0.000000] DMI: Dell Inc. PowerEdge R940xa/0TF0V7, BIOS 2.3.10 08/15/2019
s

dmidecode | grep -A4 -i 'system information'
System Information
	Manufacturer: Dell Inc.
	Product Name: PowerEdge R940xa
	Version: Not Specified
	Serial Number: 1T13Z03
```

```
# 可以使用一下命令查使用CPU最多的10个进程     
ps -aux | sort -k3nr | head -n 10
# 可以使用一下命令查使用内存最多的10个进程     
ps -aux | sort -k4nr | head -n 10
```

