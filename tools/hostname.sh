#!/bin/bash

read -p 'Input hostname: ' OS_HOSTNAME

hostname $OS_HOSTNAME
sed -i "s#HOSTNAME.*#HOSTNAME=${OS_HOSTNAME}#" /etc/sysconfig/network
sed -i "s#127.*#127.0.0.1  localhost ${OS_HOSTNAME}#" /etc/hosts

echo 'Hostname has been set, you need logout and login agin to take effect.'
