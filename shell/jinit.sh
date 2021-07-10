#!/bin/bash

WORK_DIR=$(pwd)

# Use root
[[ $EUID -ne 0 ]] && echo "Error: This script must be run as root" && exit 1

# Close selinux
sed -i 's/mingetty tty/mingetty --noclear tty/' /etc/inittab
sed -i 's/SELINUX=permissive/SELINUX=disabled/' /etc/selinux/config
sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config

cat >> /etc/profile <<EOF

export PS1='\u@\h:\w\n\\$ '

EOF

# Close unuseful
systemctl disable 'postfix'
systemctl disable 'NetworkManager'
systemctl disable 'abrt-ccpp'


groupadd -g 20000 test
useradd -g test -u 20000 -s /bin/bash -c "Dev user" -m -d /home/test test
echo test.com | passwd --stdin test

# config sudoers
sed -i 's/^Defaults    requiretty/#Defaults    requiretty/' /etc/sudoers
sed -i 's/^Defaults    env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR \\/Defaults    env_keep = "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR SSH_AUTH_SOCK \\/' /etc/sudoers

cat >> /etc/sudoers <<EOF

# test user sudo
%test    ALL=(ALL)    NOPASSED: ALL

EOF

# 电源管理
sed -i '/GRUB_CMDLINE_LINUX/{s/"$//g;s/$/ intel_pstate=disable intel_idle.max_cstate=0 processor.max_cstate=1 idle=poll"/}' /etc/default/grub


# sysctl config
found=`grep -c net.ipv4.tcp_tw_rrectcle /etc/sysctl.conf`
if ! [ $found -gt "0" ]; then
cat >> /etc/sysctl <<EOF

EOF
fi

sysctl -p

# Max open files
found=`grep -c "^* soft nproc" /etc/security/limits.conf`
if ! [ $found -gt "0" ]; then
cat >> /etc/security/limits.conf <<EOF
* soft    nproc    2048
* hard    nproc    16384
* soft    nofile    8192
* hard    nofile    65536
EOF
fi

# ssh config
sed -i 's/.*Port[[:space:]].*$/Port 9922/' /etc/ssh/ssh_config
sed -i 's/.*Port[[:space:]].*$/Port 9922/' /etc/ssh/sshd_config
sed -i 's/port=\"9922\"/port=\"22\"/' /usr/lib/firewalld/services/ssh.xml
firewall-cmd --reload

# command history
found=`grep -c HISTTIMEFORMAT /etc/profile`
if ! [ $found -gt "0" ]; then
echo "export  HISTSIZE=2000" >> /etc/profile
echo "export  HISTTIMEFORMAT='%F %T:'" >> /etc/profile
fi


cd /root/
cd ${WORK_DIR}

sh ./autoconfigip.sh

