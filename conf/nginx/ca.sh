#!/bin/bash
if [ -e "/usr/local/nginx/conf/moss.pem" ];then
    exit 0
else
    PRE_VHOST_DN=www.example.com
    umask 77
    openssl req -utf8 -newkey rsa:2048 -keyout /usr/local/nginx/conf/moss.key -nodes -x509 -days 1825 -out /usr/local/nginx/conf/moss.crt -set_serial 0 -subj "/C=CN/ST=Moss/L=Moss/O=Moss Inc/CN=$VHOST_DN"
    cat /usr/local/nginx/conf/moss.key >  /usr/local/nginx/conf/moss.pem
    echo ""                           >> /usr/local/nginx/conf/moss.pem
    cat /usr/local/nginx/conf/moss.crt >> /usr/local/nginx/conf/moss.pem
fi
