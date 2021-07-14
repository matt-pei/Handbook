#!/bin/bash

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/common.sh
# source $DIR/deployment

set +o noglob

item=0

h2 "[Set $item]: Checking nvidia devices..."; let item+=1
check_nvidia

h2 "[Set $item]: Initialize the system..."; let item+=1
initialize > /dev/null

h2 "[Set $item]: Install the Docker service..."; let item+=1
docker_install

h2 "[Set $item]: Start installing the NVIDIA Docker tool..."; let item+=1
nvidia_docker

h2 "[Set $item]: Checking if docker is installed ..."; let item+=1
check_docker

h2 "[Set $item]: Checking docker-compose is installed ..."; let item+=1
check_dockercompose

h2 "[Set $item]: Install the JDK environment and configure the up-server service"; let item+=1
jdk_install

if [ -n "$(docker-compose ps -q)" ]
then
    note "Stop Deploying the Service..."
    docker-compose down -v
fi
echo ""

h2 "[Set $item]: Starting deployment..."
docker-compose up -d
docker run -dit --restart always --name ai-server --gpus all \
        --network host --ulimit core=0:0 -p 28865:28865 \
        -v /data/aibox-common/ai-server/logs:/home/nvidia/aibox/logs \
        -v /data/aibox-common/aimodel:/home/nvidia/aibox/aimodel \
        -v /data/aibox-common/common:/home/nvidia/aibox/common \
        -v /etc/localtime:/etc/localtime:ro 192.168.176.230:8090/rz2.1.0.0/ai-mgt:v2.0.2.6

sucess $"----Deployment has been installed and started successfully.----"



