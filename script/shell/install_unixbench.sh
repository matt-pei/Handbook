#!/bin/bash

cur_dir=/opt/src/unixbench

if [ ! -f ${cur_dir} ]; then
    mkdir -p ${cur_dir}
fi

# Check System
[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root" && exit 1
[[ -f /etc/redhat-release ]] && os='centos'
[[ ! -z "`egrep -i debian /etc/issue`" ]] && os='debian'
[[ ! -z "`egrep -i ubuntu /etc/issue`" ]] && os='ubuntu'
[[ "$os" == '' ]] && echo "Error: Your system is not supported to run it!" && exit 1

# Install necessary libaries
if [ "$os" == 'centos' ]; then
    yum -y install make automake gcc autoconf gcc-c++ time perl-Time-HiRes
else
    apt-get -y update
    apt-get -y install make automake gcc autoconf perl
fi

# Create download dir
mkdir -p ${cur_dir}
cd ${cur_dir}

# Download unnixbench
if [ -s UnixBench5.1.3.tgz ]; then
    echo "UnixBench5.1.3.tgz [Found]"
else
    echo "UnixBench5.1.3.tgz not found! download now ..."
    if ! wget -c https://github.com/; then
        echo "Failed to download UnixBench5.1.3.tgz, Please download it to ${cur_dir} directory manually and try again."
        exit 1
    fi
fi

tar zxf UnixBench5.1.3.tgz && rm -f UnixBench5.1.3.tgz
cd Unnixbench/

# Run unnixbench
make
./Run 

echo
echo
echo "====== Script description and score comparison completed ======"
echo
echo
