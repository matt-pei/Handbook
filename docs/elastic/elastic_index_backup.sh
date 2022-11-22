#!/bin/bash
INDEX=(hdms_nginxlog hdms_cacenter_test com.navinfo.imp.id hdms_task)
Month=`date +%B`
YESTERDAY=`date -d '-1 day' +%Y%m%d`
INDEX_TIME=`date -d '-1 day' +%Y-%m-%d`
IpAddress=10.9.4.86
# INDEX=(hdms_nginxlog)


function repository_status() {
    res=`echo $?`
    if [[ $res != "0" ]]; then
        echo "ES repository fails to be created"
    else
        echo "ES repository is successfully created"
    fi
}

function back_status() {
    res=`echo $?`
    if [[ $res != "0" ]]; then
        echo "ES Index backup failed"
    else
        echo "ES Index backup succeeded"
    fi
}


ESStatus=$(curl -I -sL -m 5  http://${IpAddress}:9200 | grep '200')
if [[ "${ESStatus}" != "" ]]; then
    echo "ES Status: ${ESStatus}"
    # 创建s3存储桶目录文件
    for i in ${INDEX[@]}
    do
        # 循环创建仓库
        curl -H "Content-Type: application/json" -XPUT http://${IpAddress}:9200/_snapshot/${i}-${YESTERDAY} -d '
        {
            "type": "s3",
            "settings": {
                "bucket": "data-backup-hdms-cn-northwest",
                "region": "cn-northwest-1",
                "base_path": "'${i}'/'${i}'-'${YESTERDAY}'/",
                "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
            }
        }'
        # Example: hdms_nginxlog-20220906/hdms_cacenter_test-20220906/hdms_task-20220906/com.navinfo.imp.id-20220906
        aws s3api put-object --bucket data-backup-hdms-cn-northwest --key ${i}/${Month}/${i}-${YESTERDAY}/
        # 创建备份仓库
        if [[ "${i}" == "hdms_nginxlog" ]]; then
            curl -H "Content-Type: application/json" -XPUT http://${IpAddress}:9200/_snapshot/${i}-${YESTERDAY} -d '
            {
                "type": "s3",
                "settings": {
                    "bucket": "data-backup-hdms-cn-northwest",
                    "region": "cn-northwest-1",
                    "base_path": "'${i}'/'${i}'-'${YESTERDAY}'/",
                    "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
                }
            }'
            repository_status
        elif [[ "${i}" == "hdms_cacenter_test" ]]; then
            curl -H "Content-Type: application/json" -XPUT http://${IpAddress}:9200/_snapshot/${i}-${YESTERDAY} -d '
            {
                "type": "s3",
                "settings": {
                    "bucket": "data-backup-hdms-cn-northwest",
                    "region": "cn-northwest-1",
                    "base_path": "'${i}'/'${i}'-'${YESTERDAY}'/",
                    "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
                }
            }'
            repository_status
        elif [[ "${i}" == "com.navinfo.imp.id" ]]; then
            curl -H "Content-Type: application/json" -XPUT http://${IpAddress}:9200/_snapshot/${i}-${YESTERDAY} -d '
            {
                "type": "s3",
                "settings": {
                    "bucket": "data-backup-hdms-cn-northwest",
                    "region": "cn-northwest-1",
                    "base_path": "'${i}'/'${i}'-'${YESTERDAY}'/",
                    "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
                }
            }'
            repository_status
        elif [[ "${i}" == "hdms_task" ]]; then
            curl -H "Content-Type: application/json" -XPUT http://${IpAddress}:9200/_snapshot/${i}-${YESTERDAY} -d '
            {
                "type": "s3",
                "settings": {
                    "bucket": "data-backup-hdms-cn-northwest",
                    "region": "cn-northwest-1",
                    "base_path": "'${i}'/'${i}'-'${YESTERDAY}'/",
                    "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
                }
            }'
            repository_status
        else
            echo "Invalid index name or created index name not found"
        fi
            # 备份索引
            echo "Start backup"
            curl -H "Content-Type: application/json" -XPUT http://${IpAddress}:9200/_snapshot/${i}-${YESTERDAY}/${i}-${YESTERDAY}?wait_for_completion=true -d '
            {
                "indices": "'${i}'_'${INDEX_TIME}'"
            }'
            back_status
    done
else
    echo "ES Status: ${ESStatus}"
    exit 1
fi


