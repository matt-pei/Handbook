#!/bin/bash

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
source $DIR/common
source $DIR/deployment

set +o noglob

item=0

h2 "[Set $item]: Checking nvidia devices..."; let item+=1
check_nvidia

h2 "[Set $item]: Checking if docker is installed ..."; let item+=1
check_docker

h2 "[Set $item]: Checking docker-compose is installed ..."; let item+=1
check_dockercompose

h2 "[Set $item]: Starting deployment ..."
docker-compose up -d

sucess $"----Deployment has been installed and started successfully.----"


