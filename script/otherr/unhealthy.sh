#！/bin/bash

docker ps -a | grep -i unhealthy
if [ $? -eq 0 ]; then
    docker restart `docker ps -a | grep -i unhealthy | awk '{print $1}'` > ./unhealthy.log
    if [ $? -eq 0 ]; then
        echo "Restart successfully !"
    else
        echo "Restart Failed !!!"
    fi
else
    echo "The Container is healthy, No need to restart !"
fi







