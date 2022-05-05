# Prometheus监控

#### 启动prometheus
```
docker run -dit --restart=always --name prometheus -p 9090:9090 -v /opt/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml prom/prometheus:v2.18.1
```

#### 启动grafana
```
docker run -dit --restart always --name=grafana -p 3000:3000 -v /data/devops/grafana_storage:/var/lib/grafana grafana/grafana:6.7.4
```
#### 启动node-exporter
```
docker pull prom/node-exporter:v0.18.1
docker pull prom/node-exporter:v1.0.1

docker run -dit --restart always --name node-exporter -p 9100:9100 --net="host" --pid="host" -v "/proc:/host/proc:ro" -v "/sys:/host/sys:ro" -v "/:/host:ro,rslave" prom/node-exporter:v1.3.1 --path.rootfs=/host

docker run -d \
  --net="host" \
  --pid="host" \
  -v "/:/host:ro,rslave" \
  quay.io/prometheus/node-exporter:latest \
  --path.rootfs=/host
```

#### 监控nvidia GPU
```
docker run -dit \
    -p 9400:9400 \
    --gpus all \
    --restart always \
    --name dcgm-exporter \
    nvidia/dcgm-exporter:1.7.2
```

