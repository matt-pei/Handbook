
## Elasticsearch
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



