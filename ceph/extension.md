# 

## 一、ceph扩容

```
# 横向扩容: 增加节点
# 纵向扩容: 增加磁盘
```
```
# 清空磁盘
ceph-deploy disk zap ceph001 /dev/sdc
# 添加磁盘
ceph-deploy osd create ceph001 --data /dev/sdc
# 临时关闭rebalance
ceph osd set norebalance    # 数据分布
ceph osd set nobackfill     # 数据填充
ceph osd unset norebalance
ceph osd unset nobackfill
# 查看osd延时
ceph osd perf
# 剔除osd
ceph osd out osd.5
ceph osd crush rm osd.5
ceph osd rm osd.5
ceph auth rm osd.5
```

```
# 数据一致性
ceph pg scrub xxxx
ceph pg deep-scrub xxxx
```

## 集群运维

```
systemctl restart ceph-osd@
```

### 2、服务日志

```
# 日志所在位置
/var/log/ceph/
```

### 3、监控集群
```
ceph status
# 动态查看集群状态
ceph -w
# 查看资源空间
ceph df
# 
ceph osd stat
ceph osd dump
ceph osd tree
ceph osd df
#
ceph mon stat
ceph mon dump
ceph quorum_status
# 查看socket信息
ceph --admin-daemon /var/run/ceph/xxxxx.asok
```

### 4、资源池管理
```
ceph osd pool get pool
# 设置副本数
ceph osd pool set pool-demo size 4
ceph osd pool get pool-demo size
# 设置pg
ceph osd pool set pool-demo pg_num 32
ceph osd pool get pool-demo pg_num
# 设置pgp
ceph osd pool set pool-demo pgp_num 32
ceph osd pool get pool-demo pgp_num
# 设置分类
ceph osd pool application get pool-demo
ceph osd pool application enable pool-demo rbd
# 设置配额
ceph osd pool set-quota pool-demo max_objects 100
ceph osd pool get-quata pool-demo
# 统计
rados df
# 删除资源池
ceph osd pool rm pool-demo pool-demo --yes-i-really-really-mean-it
# 
ceph --admin-demo /var/run/ceph/xxxx.asok config set mon_allow_pool_delete true
```

