# Harbor
### Our mission is to be the trusted cloud native repository for Kubernetes

<img alt="Harbor" src="../../images/harbor_logo.png"  />

---

## 目录

1. [What is Harbor?]()
2. [Harbor安装先决条件]()

### What is Harbor?
Harbor是一个开放源代码注册中心，可通过策略和基于角色的访问控制来保护工件，确保扫描图像并消除漏洞，并将图像签名为受信任的。Harbor是CNCF毕业的项目，可提供合规性，性能和互操作性，以帮助您跨Kubernetes和Docker等云原生计算平台持续，安全地管理工件。

### Harbor安装先决条件
Harbor被部署为多个Docker容器。因此，您可以将其部署在任何支持Docker的Linux发行版上。目标主机需要Docker和Docker Compose才能安装。

#### 硬件
下表列出了用于部署Harbor的最低和建议的硬件配置。

资源 &emsp; &emsp; 最低要求 &emsp; &emsp; &ensp; 推荐

---

CPU &emsp; &emsp; &ensp; 2 CPU &emsp; &emsp; &emsp; 4 CPU

---

Mem	&emsp; &emsp; &ensp; 4 GB &emsp; &emsp; &emsp; &ensp; 8 GB

---

Disk &emsp; &emsp; &ensp; 40 GB &emsp; &emsp; &emsp; &ensp;160 GB

### 网络端口
Harbor要求在目标主机上打开以下端口。

Port &emsp;&emsp;&emsp; 协议 &emsp;&emsp;&emsp; 描述

***

443 &emsp; &emsp; &ensp; HTTPS &emsp; &emsp; Harbor门户和核心API在此端口上接受HTTPS请求。您可以在配置文件中更改此端口。

---

4443 &emsp; &emsp; &ensp;HTTPS &emsp; &emsp;与Harbor的Docker内容信任服务的连接。仅在启用Notary的情况下才需要。您可以在配置文件中更改此端口。

---

80 &emsp; &emsp; &emsp; &ensp;HTTP &emsp; &emsp;Harbor入口和核心API在此端口上接受HTTP请求。您可以在配置文件中更改此端口。


#### 下载harbor安装包
```
# 下载离线安装包
wget -c https://github.com/goharbor/harbor/releases/download/v2.0.0/harbor-offline-installer-v2.0.0.tgz
# 下载在线安装包
wget -c https://github.com/goharbor/harbor/releases/download/v2.0.0/harbor-online-installer-v2.0.0.tgz
```