# Prmetheus
### introduce
#### 什么是普罗米修斯？
Prometheus是最初在SoundCloud上构建的开源系统监视和警报工具包 。自2012年成立以来，许多公司和组织都采用了Prometheus，该项目拥有非常活跃的开发人员和用户社区。现在，它是一个独立的开源项目，并且独立于任何公司进行维护。为了强调这一点并阐明项目的治理结构，Prometheus 于2016年加入了 Cloud Native Computing Foundation，这是继Kubernetes之后的第二个托管项目。

#### 特征
普罗米修斯的主要特点是：
* 一个多维数据模型，其中包含通过度量标准名称和键/值对标识的时间序列数据
* PromQL，一种灵活的查询语言 ，可利用此维度
* 不依赖分布式存储；单服务器节点是自治的
* 时间序列收集通过HTTP上的拉模型进行
* 通过中间网关支持推送时间序列
* 通过服务发现或静态配置发现目标
* 多种图形和仪表板支持模式
#### 组件
Prometheus生态系统包含多个组件，其中许多是可选的：
* Prometheus主服务器，它会刮取并存储时间序列数据
* 客户端库，用于检测应用程序代码
* 一个支持短期工作的推送网关
* 诸如HAProxy，StatsD，Graphite等服务的专用出口商
* 一个alertmanager处理警报
各种支持工具
* 大多数Prometheus组件都是用Go编写的，因此易于构建和部署为静态二进制文件。

#### 架构
下图说明了Prometheus的体系结构及其某些生态系统组件：
<img alt="架构图" src="../../images/prometheus/architecture.png" width = "800" height = "200" />

## Catalogue







