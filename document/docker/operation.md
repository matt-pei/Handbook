# Docker swarm operation

### 查看docker config详细信息
```
docker config inspect -f '{{json .Spec.Data}} ' redis-cnf |cut -d '"' -f2 |base64 -d
```

