#！/bin/bash

version='6.2.0'
k8s1.13='harbor1.datacanvas.com'
k8s1.19='harbor7.datacanvas.com'


function deploy_app() {
    deploy_server="pipes compass falcon mpserver openapiv1 controller heron livywrapper mrserver specserver daas mdserver msserver tenantserver oauthserver recorder"
    for i in ${deploy_server}; do
        sudo rm -rf /mnt/aps/apsservice/$i/app.yaml.template
        sudo rsync $WORKSPACE/script/app.yaml.template /mnt/aps/apsservice/$i/app.yaml.template
        sudo chown 3000:3000 /mnt/aps/apsservice/$i/app.yaml.template
        sudo /mnt/aps/apsservice/deploy_app.sh $i $TAG
        sudo chown 3000:3000 /mnt/aps/apsservice/$i/app.yaml
    done
}

function public() {
    docker login harbor.zetyun.com --username=admin --password=zetyunHARbor
    docker pull harbor.zetyun.com/aps$version/service/system/$1:$version
    docker tag harbor.zetyun.com/aps$version/service/system/$1:$version registry.aps.datacanvas.com:5000/aps/service/system/$1:$version
    docker login registry.aps.datacanvas.com:5000 --username=admin --password=Server2008!
    docker push registry.aps.datacanvas.com:5000/aps/service/system/$1:$version
}

function pipes() {
    pipe_server="pipes pipes-console operationcenter"
    docker login registry.aps.datacanvas.com:5000 --username=admin --password=Server2008!
    for i in ${pipe_server}
    do
        docker pull harbor.zetyun.com/aps$version/service/system/$i:$version
        docker tag harbor.zetyun.com/aps$version/service/system/$i:$version registry.aps.datacanvas.com:5000/aps/service/system/$i:$version
        docker push registry.aps.datacanvas.com:5000/aps/service/system/$i:$version
    done

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/pipes/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/pipes/app.yaml && echo "服务更新成功，等待开放端口中..." 
    kubectl delete pod -n aps-os `kubectl get pod -n aps-os | grep console | awk '{print $1}'`
    kubectl delete pod -n aps-os `kubectl get pod -n aps-os | grep operationcenter | awk '{print $1}'`
}
function compass() {
    compass_server="compass2_sentry datasets automl modelstore extension mf lab analysis console operation-center system resource model-service"
    docker login registry.aps.datacanvas.com:5000 --username=admin --password=Server2008!
    for i in ${compass_server}
    do
        docker pull harbor.zetyun.com/aps$version/service/system/$i:$version
        if [ $i == "compass2_sentry" ]; then
            docker tag harbor.zetyun.com/aps$version/service/system/compass2_sentry:$version registry.aps.datacanvas.com:5000/aps/service/system/compass:$version
            docker push registry.aps.datacanvas.com:5000/aps/service/system/compass:$version
        else
            docker tag harbor.zetyun.com/aps$version/service/system/$i:$version registry.aps.datacanvas.com:5000/aps/service/system/$i:$version
            docker push registry.aps.datacanvas.com:5000/aps/service/system/$i:$version
        fi
    done

    ## Deploy
    deploy_app  # Common deployment templates
    sudo sed -ri s#10.68.0.2#10.76.0.2# /mnt/aps/apsservice/compass/app.yaml
    sudo kubectl delete -f /mnt/aps/apsservice/compass/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/compass/app.yaml && echo "服务更新成功，等待开放端口中" 
}

function falcon() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/falcon/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/falcon/app.yaml && echo "服务更新成功，等待开放端口中..."
}
function mpserver() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/mpserver/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/mpserver/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc mpserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31354}]}}' -n aps-os
    while [[ "$( kubectl  patch svc mpserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31354}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function openapiv1() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/openapiv1/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/openapiv1/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc openapiv1-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31471}]}}' -n aps-os
    while [[ "$( kubectl  patch svc openapiv1-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31471}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function controller() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/controller/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/controller/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc controller-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31168},{"port":8082,"nodePort":31866}]}}' -n aps-os
    while [[ "$( kubectl  patch svc controller-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31168},{"port":8082,"nodePort":31866}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function heron() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/heron/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/heron/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc heron-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31403},{"port":8082,"nodePort":31461}]}}' -n aps-os
    while [[ "$( kubectl  patch svc heron-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31403},{"port":8082,"nodePort":31461}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function livywrapper() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/livywrapper/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/livywrapper/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc livywrapper-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31454},{"port":8082,"nodePort":31335}]}}' -n aps-os
    while [[ "$( kubectl  patch svc livywrapper-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31454},{"port":8082,"nodePort":31335}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function mrserver() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/mrserver/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/mrserver/app.yaml && echo "服务更新成功，等待开放端口中..."
    # echo "更新mrserver jars包"
    sudo rm -rf /mnt/aps/apsservice/mrserver/jars/* 
    sudo scp aps@172.20.51.11:/mnt/aps/dev/apsservice/mrserver/jars/* /mnt/aps/apsservice/mrserver/jars/
    sudo chown -R 3000:3000 /mnt/aps/apsservice/mrserver/jars 
    # Open port
    #kubectl  patch svc mrserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31742}]}}' -n aps-os
    while [[ "$( kubectl  patch svc mrserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31742}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function specserver() {
    public $1

    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/specserver/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/specserver/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc specserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31539}]}}' -n aps-os
    while [[ "$( kubectl  patch svc specserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31539}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function uums() {
    public $1

    ## Deploy
    #sudo kubectl delete -f /mnt/aps/apsservice/uums/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/uums/app.yaml && echo "服务更新成功，等待开放端口中..."
    sudo kubectl delete pods -n aps-os -l app=uums
    # Open port
    #kubectl  patch svc  uums-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31019}]}}' -n aps-os
    while [[ "$( kubectl  patch svc  uums-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31019}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function daas() {
    public $1
    
    ## Deploy
    deploy_app  # Common deployment templates
    #sleep 1800
    sudo kubectl delete -f /mnt/aps/apsservice/daas/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/daas/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc daas-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31723}]}}' -n aps-os
    while [[ "$( kubectl  patch svc daas-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31723}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
    #curl -X POST -u liuyt:116d2ff2f85cba7286572c7b88f589415b http://jenkins.zetyun.cn:8080/job/aps_test_daas-job/build
}
function mdserver() {
    docker pull harbor.zetyun.com/aps$version/service/system/mdserver:$version
    docker tag harbor.zetyun.com/aps$version/service/system/mdserver:$version registry.aps.datacanvas.com:5000/aps/service/system/mdserver:$version
    docker pull harbor.zetyun.com/aps$version/service/system/mdserver-tf2:$version
    docker tag harbor.zetyun.com/aps$version/service/system/mdserver-tf2:$version registry.aps.datacanvas.com:5000/aps/service/system/mdserver-tf2:$version
    docker login registry.aps.datacanvas.com:5000 --username=admin --password=Server2008!
    docker push registry.aps.datacanvas.com:5000/aps/service/system/mdserver:$version
    docker push registry.aps.datacanvas.com:5000/aps/service/system/mdserver-tf2:$versio
    
    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/mdserver/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/mdserver/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl patch svc mdserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31355},{"port":8081,"nodePort":31356}]}}' -n aps-os
    while [[ "$( kubectl patch svc mdserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31355},{"port":8081,"nodePort":31356}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function msserver(){
    public $1
    
    ## Deploy
    deploy_app  # Common deployment templates
    # Open port
    #kubectl  patch svc msserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31739}]}}' -n aps-os
    #while [[ "$( kubectl  patch svc msserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31738}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
    while [[ "$( kubectl  patch svc msserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31738},{"port":8090,"nodePort":31085}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function tenantserver(){
    public $1
    
    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/tenantserver/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/tenantserver/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl patch svc tenantserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31747}]}}' -n aps-os
    while [[ "$( kubectl patch svc tenantserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31747}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function oauthserver(){
    public $1
    
    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/oauthserver/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/oauthserver/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc oauthserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31876}]}}' -n aps-os
    while [[ "$( kubectl  patch svc oauthserver-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31876}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function recorder(){
    public $1
    
    ## Deploy
    deploy_app  # Common deployment templates
    sudo kubectl delete -f /mnt/aps/apsservice/recorder/app.yaml || /bin/true  && sudo kubectl apply -f /mnt/aps/apsservice/recorder/app.yaml && echo "服务更新成功，等待开放端口中..."
    # Open port
    #kubectl  patch svc recorder-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31616},{"port":8081,"nodePort":31891}]}}' -n aps-os
    while [[ "$( kubectl  patch svc recorder-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31553},{"port":8081,"nodePort":31554}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        echo "waiting port release"
        sleep 1
    done
}
function hdfswrapper(){
    docker pull harbor.zetyun.com/aps$version/service/system/hdfswrapper-2.6.0:$version
    docker tag harbor.zetyun.com/aps$version/service/system/hdfswrapper-2.6.0:$version registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.6.0:$version
    # docker pull harbor.zetyun.com/aps$version/service/system/hdfswrapper-2.5.0:$version
    # docker tag harbor.zetyun.com/aps$version/service/system/hdfswrapper-2.5.0:$version registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.5.0:$version
    docker login registry.aps.datacanvas.com:5000 --username=admin --password=Server2008!
    docker push registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.6.0:$version
    # docker push registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.5.0:$version
    # docker -H 172.20.51.17:5555 pull registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.5.0:$version
    # docker -H 172.20.51.16:5555 pull registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.5.0:$version
    # docker -H 172.20.51.19:5555 pull registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.5.0:$version
    docker -H 172.20.51.17:5555 pull registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.6.0:$version
    docker -H 172.20.51.16:5555 pull registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.6.0:$version
    docker -H 172.20.51.19:5555 pull registry.aps.datacanvas.com:5000/aps/service/system/hdfswrapper-2.6.0:$version

    ## Deploy
    for i in `kubectl get  pod -n aps-os | grep hdfswrapper | awk '{print $1}'`;do kubectl delete pod $i --grace-period=0 --force -n aps-os;done
    sleep 40
    echo "服务更新成功..." 
    # Open port
    #kubectl  patch svc heron-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31403},{"port":8082,"nodePort":31461}]}}' -n aps-os
    #while [[ "$( kubectl  patch svc falcon-svc -p '{"spec":{"type":"NodePort","ports":[{"port":8080,"nodePort":31178}]}}' -n aps-os 2>&1  |grep allocated)" != "" ]];do
        #echo "waiting port release"
        #sleep 1
    #done
}

say() {
    printf 'rustup: %s\n' "$1"
}
error() {
    say "$1" >&2
    exit 1
}

case "$1" in
    pipes)
        pipes
        ;;
    compass)
        compass
        ;;
    falcon)
        falcon $1
        ;;
    mpserver)
        mpserver $1
        ;;
    openapiv1)
        openapiv1 $1 
        ;;
    controller)
        controller $1
        ;;
    heron)
        heron $1
        ;;
    livywrapper)
        livywrapper $1
        ;;
    mrserver)
        mrserver $1
        ;;
    specserver)
        specserver $1 
        ;;
    uums)
        uums $1 
        ;;
    daas)
        daas $1
        ;;
    mdserver)
        mdserver
        ;;
    msserver)
        msserver $1 
        ;;
    tenantserver)
        tenantserver $1
        ;;
    cephfs)
        pass
        ;;
    hostpath)
        pass
        ;;
    oauthserver)
        oauthserver $1 
        ;;
    recorder)
        recorder $1
        ;;
    tenantwebhook)
        tenantwebhook
        ;;
    hdfswrapper)
        pass
        ;;
    livyserver)
        livyserver
        ;;
    sparkhistory)
        pass
        ;;
    all)
        pipes
        compass
        hdfswrapper
        public_build="falcon mpserver openapiv1 controller heron livywrapper mrserver specserver uums daas msserver tenantserver oauthserver recorder"
        for i in ${public_build}
        do
            public $i
        done
        ;;
    *)
        error "Error"
esac



