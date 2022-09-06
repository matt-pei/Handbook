#!/bin/bash
DATA_DIR=/efs/elastic
S3_DIR=
YESTERDAY=`date -d '-1 day' +%Y%m%d`
INDEX_TIME=`date -d '-1 day' +%Y-%m-%d`
#INDEX=(hdms_nginxlog hdms_cacenter_test com.navinfo.imp.id hdms_task)
INDEX=(hdms_nginxlog)


esStatus=$(curl -I -sL -m 5  http://10.9.4.86:9200 | grep 200)
if [[ "${esStatus}" != "" ]]; then
    echo "ES Status: ${esStatus}"
    # 判断备份目录是否存在
    #for i in ${INDEX[@]}
    #do
    #    if [[ ! -d ${DATA_DIR}/${i}-${YESTERDAY} ]]; then
    #        mkdir -pv ${DATA_DIR}/${i}-${YESTERDAY}
    #    fi
    #done
    # 创建仓库
    for i in ${INDEX[@]}
    do
    # 创建备份仓库
    curl -H "Content-Type: application/json" -XPUT http://10.9.4.86:9200/_snapshot/${i}-${YESTERDAY} -d '
    {
        "type": "s3",
        "settings": {
            "bucket": "data-backup-hdms-cn-northwest",
            "region": "cn-northwest-1",
            "base_path": "'${i}'-'${YESTERDAY}'",
            "endpoint": "s3.cn-northwest-1.amazonaws.com.cn"
        }
    }'
    res=`echo $?`
    if [[ $res != "1" ]]; then
        echo "es仓库创建失败"
    else
        echo "es仓库创建成功"
        # for i in ${INDEX[@]}
        # do
        # 备份索引
        curl -H "Content-Type: application/json" -XPUT http://10.9.4.86:9200/_snapshot/${i}-${YESTERDAY}/${i}-${YESTERDAY}?wait_for_completion=true -d '
        {
            "indices": "'${i}'_'${INDEX_TIME}'"
        }'
        # done
    fi
    done

else
    echo "ES Status: ${ESStatus}"
    exit 1
fi





