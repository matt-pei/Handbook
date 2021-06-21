#!/bin/bash

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/common
source $DIR/deployment

set +o noglob

item=0

h2 "[Set $item]: Checking nvidia devices..."; let item+=1
check_nvidia

h2 "[Set $item]: Initialize the system..."; let item+=1
initialize

h2 "[Set $item]: Install the Docker service..."; let item+=1
docker_install

h2 "[Set $item]: Start installing the NVIDIA Docker tool..."; let item+=1
nvidia_docker

h2 "[Set $item]: Checking if docker is installed ..."; let item+=1
check_docker

h2 "[Set $item]: Checking docker-compose is installed ..."; let item+=1
check_dockercompose

if [ -n "$(docker-compose ps -q)" ]
then
    note "Stop Deploying the Service..."
    docker-compose down -v
fi
echo ""

h2 "[Set $item]: Starting deployment..."
docker-compose up -d

sucess $"----Deployment has been installed and started successfully.----"





