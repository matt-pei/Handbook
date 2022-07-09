
## 一、Redis
```
get 

keys
# zset类型
ZRANGE xxxxxx 0 -1 withscores
```

```
# 导出redis所有的keys
/opt/redis-5.0.13/src/redis-cli --raw -h pro-ec-rd-id-ro.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 --scan >> ./redis_ecrd_all_key.csv

# 查看redis最大的keys
/opt/redis-5.0.13/src/redis-cli -h pro-dsg-redis-ro.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 --scan --bigkeys
``` 

```
# 删除redis key 预生产环境
./redis-cli -h pre-ec-rd-id.rwzege.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 KEYS oso:cloud_pre* | xargs -r -t -n1 ./redis-cli -h pre-ec-rd-id.rwzege.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 DEL

# Del redis key 生产环境
## Ip: 4.229
/data/aws-redis/redis-stable/src/redis-cli -h pro-ec-rd-id.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 keys oso:xxxx* | xargs /data/aws-redis/redis-stable/src/redis-cli -h pro-ec-rd-id.nyswuz.ng.0001.cnw1.cache.amazonaws.com.cn -p 6379 del
```

## pg数据库
```
## 清空数据库表数据
delete from daimler02.hcc_attributes;
```


# 安装repository-s3
## 备份ES数据到AWS S3上
```
elasticsearch-plugin install repository-s3
# elasticsearch-plugin remove repository-s3

```






## 二、Elasticsearch
### 快照备份
```
# 创建快照仓库
# 如果想使用验证功能，创建仓库时去掉 ?verify=false 参数即可
curl -X PUT "xx.xx.xx.xx:9200/_snapshot/xxxxx?verify=false" -H 'Content-Type: application/json' -d'{
  "type": "fs",
  "settings": {
    "location": "/xxx/xxx/xxx",
    "compress": true,   # 是否压缩源文件，默认为true
    "max_restore_bytes_per_sec": 50m,   # 指定数据恢复速度，默认为 40m/s
    "max_snapshot_bytes_per_sec": 30m   # 指定创建快照时的速度，默认为 40m/s
  }
}'

# 查看已注册快照仓库
curl -X GET "10.201.6.97:9200/_snapshot?pretty"
curl -X GET "10.201.6.97:9200/_snapshot/_all?pretty"

# 查看快照仓库列表
curl -X GET "10.201.6.97:9200/_cat/repositories?v"
# 查看快照信息
curl -X GET "10.201.6.97:9200/_snapshot/xxxx/syslog?pretty"
```

```
# 备份部分索引
curl -XPUT 'http://10.201.6.97:9200/_snapshot/xxxxxx/xxxxx-kjh-20220127' -H 'Content-Type: application/json' -d '{ "indices": "xxxxx-kjh-2022.01.27", "ignore_unavailable": true, }'
```



curl -X PUT "10.201.6.97:9200/_snapshot/es_data_backup?verify=false" -H 'Content-Type: application/json' -d'{
  "type": "fs",
  "settings": {
    "location": "/efs/es_data_backup",
    "compress": true,   # 是否压缩源文件，默认为true
    "max_restore_bytes_per_sec": 50m,   # 指定数据恢复速度,默认为 40m/s
    "max_snapshot_bytes_per_sec": 50m   # 指定创建快照时的速度,默认为 40m/s
  }
}'

```
# aws s3备份key
AKIAVUXZXPFG2UAJYDFJ
BptW2/fBfKaKsbNoqxwEoQL9AmYxP0c3Ovpfn03S
```



