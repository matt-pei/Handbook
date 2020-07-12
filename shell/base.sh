#!/bin/bash
#!/usr/bin/env bash



# expr 数学运算（整数）

# 倒计时
for time in `seq 9 -1 0`;do
    echo -e -n "\b$time"
    sleep 1
done
echo

dirname $0 :取得当前执行脚本文件的父目录

