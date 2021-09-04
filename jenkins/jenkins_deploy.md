# Jenkins

## 一、jenkins部署

```
#docker启动Jenkins
mkdir -pv /data/jenkins_home
docker run -dit \
    --name jenkins \
    --restart always \
    -p 8080:8080 -p 50000:50000 \
    -v /data/jenkins_home:/var/jenkins_home \
    jenkins/jenkins:2.239
docker run -dit \
    --name jenkins \
    --restart always \
    -p 8080:8080 -p 50000:50000 \
    -v /data/jenkins_home:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/local/bin/docker:/usr/bin/docker \
    jenkins/jenkins:2.239
docker exec -it -u root jenkins bash
usermod -aG root jenkins
```

### 二、配置jenkins代理
```
# 修改Jenkins文件
vim /data/jenkins_home/hudson.model.UpdateCenter.xml
https://updates.jenkins-zh.cn/update-center.json

# 修改证书
cd /data/jenkins_home/war/WEB-INF/update-center-rootCAs/*
mkdir -p back && mv jenkins* back
vim mirror-adapter.crt
    ....
docker restart jenkins
```




