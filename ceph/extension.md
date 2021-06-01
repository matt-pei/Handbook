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





