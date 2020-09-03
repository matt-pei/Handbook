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



