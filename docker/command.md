## 一、Docker command

### 


```
# 删除未使用镜像
docker image prune -a
# 删除none的镜像
docker rmi $(docker images | grep 'none' | awk '{print $3}')
# 停止exited容器
docker stop $(docker ps -a | grep 'Exited' | awk '{print $1}')
docker stop $(docker ps -a | grep -i 'exited' | awk '{print $1}')
# 删除exited容器
docker rm $(docker ps -a | grep 'Exited' | awk '{print $1}')
```


