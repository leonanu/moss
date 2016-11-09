#!/bin/bash
## nginx-1.10.x
if ! grep '^NGINX$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist nginx
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "There already have Nginx running!"
    fi

## nginx 
    file_proc ${NGINX_SRC}
    get_file
    unpack

    ### get nginx vim files
    [ -d "${STORE_DIR}/${SRC_DIR}/contrib/vim" ] && cp -rf ${STORE_DIR}/${SRC_DIR}/contrib/vim ${STORE_DIR}/nginx_vim

    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR} \
    --pid-path=/var/run/nginx.pid \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --http-client-body-temp-path=/var/tmp/nginx/client_body \
    --http-proxy-temp-path=/var/tmp/nginx/proxy \
    --http-fastcgi-temp-path=/var/tmp/nginx/fastcgi \
    --http-uwsgi-temp-path=/var/tmp/nginx/uwsgi \
    --with-threads \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_image_filter_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_auth_request_module \
    --with-http_stub_status_module \
    --with-stream \
    --with-stream_ssl_module \
    --with-pcre \
    --without-http_ssi_module \
    --without-http_geo_module \
    --without-http_scgi_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module"

## for compile
    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/nginx'
    compile
    
    [ ! -d "${INST_DIR}/${SRC_DIR}/conf/vhosts" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/conf/vhosts

## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## user add
    id www >/dev/null 2>&1 || useradd www -u 1001 -M -s /sbin/nologin
    ## document root
    [ ! -d "${NGX_DOCROOT}" ] && mkdir -m 0755 -p ${NGX_DOCROOT}
    chown -R www:www ${NGX_DOCROOT}
    ## log directory
    [ ! -d "${NGX_LOGDIR}" ] && mkdir -m 0755 -p ${NGX_LOGDIR}
    chown -R www:www ${NGX_LOGDIR}
    ## tmp directory
    [ ! -d "/var/tmp/nginx/client_body" ] && mkdir -m 0777 -p /var/tmp/nginx/client_body
    [ ! -d "/var/tmp/nginx/fastcgi" ] && mkdir -m 0777 -p /var/tmp/nginx/fastcgi
    [ ! -d "/var/tmp/nginx/uwsgi" ] && mkdir -m 0777 -p /var/tmp/nginx/uwsgi
    [ ! -d "/var/tmp/nginx/proxy" ] && mkdir -m 0777 -p /var/tmp/nginx/proxy
    chown -R www:www /tmp/var/nginx
    ## conf
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.conf ${INST_DIR}/${SRC_DIR}/conf/nginx.conf
    install -m 0644 ${TOP_DIR}/conf/nginx/vhost.conf ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_server_name.*#server_name    ${NGX_HOSTNAME};#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_root.*#    root    ${NGX_DOCROOT};#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_access_log.*#    access_log    ${NGX_LOGDIR}/access.log moss buffer=4k;#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_error_log.*#    error_log    ${NGX_LOGDIR}/error.log error;#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    ## Vim syntax hilight
    VIM_SHARE_DIR=$(ls /usr/share/vim | grep 'vim7')
    [ ! -d "/usr/share/vim/${VIM_SHARE_DIR}/ftdetect" ] && mkdir -m 0755 -p /usr/share/vim/${VIM_SHARE_DIR}/ftdetect
    [ ! -d "/usr/share/vim/${VIM_SHARE_DIR}/indent" ] && mkdir -m 0755 -p /usr/share/vim/${VIM_SHARE_DIR}/indent
    [ ! -d "/usr/share/vim/${VIM_SHARE_DIR}/syntax" ] && mkdir -m 0755 -p /usr/share/vim/${VIM_SHARE_DIR}/syntax
    cp -rf ${STORE_DIR}/${SRC_DIR}/contrib/vim ${STORE_DIR}/nginx_vim/ftdetect/* /usr/share/vim/${VIM_SHARE_DIR}/ftdetect/
    cp -rf ${STORE_DIR}/${SRC_DIR}/contrib/vim ${STORE_DIR}/nginx_vim/indent/* /usr/share/vim/${VIM_SHARE_DIR}/indent/
    cp -rf ${STORE_DIR}/${SRC_DIR}/contrib/vim ${STORE_DIR}/nginx_vim/syntax/* /usr/share/vim/${VIM_SHARE_DIR}/syntax/
    chown -R root.root /usr/share/vim/${VIM_SHARE_DIR}/
    rm -rf ${STORE_DIR}/${SRC_DIR}/contrib
    ## log
    [ ! -d "/usr/local/etc/logrotate" ] && mkdir -m 0755 -p /usr/local/etc/logrotate
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.logrotate /usr/local/etc/logrotate/nginx
    sed -i "s#/var/log/nginx#${NGX_LOGDIR}#g" /usr/local/etc/logrotate/nginx
    [ ! -d "${INST_DIR}/${SRC_DIR}/logs" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/logs
    [ ! -d "/var/log/nginx" ] && mkdir -m 0755 -p /var/log/nginx
    chown -R www:www ${INST_DIR}/${SRC_DIR}/logs
    chown -R www:www /var/log/nginx
    ## cron job
    echo '' >> /var/spool/cron/root
    echo '# Logrotate - Nginx' >> /var/spool/cron/root
    echo '0 0 * * * /usr/sbin/logrotate -f /usr/local/etc/logrotate/nginx > /dev/null 2>&1' >> /var/spool/cron/root
    chown root:root /var/spool/cron/root
    chmod 600 /var/spool/cron/root
    ## install CA
    [ ! -d '/usr/local/bin' ] && mkdir -p /usr/local/bin
    install -m 0755 ${TOP_DIR}/conf/nginx/ca.sh /usr/local/bin/ca.sh
    sed -i "s#.*PRE_VHOST_DN.*#    VHOST_DN=${NGX_HOSTNAME}#" /usr/local/bin/ca.sh
    ## create certs
    /usr/local/bin/ca.sh
    ## init scripts
    install -m 0755 ${TOP_DIR}/conf/nginx/nginx.init /etc/init.d/nginx
    chkconfig --add nginx
    chkconfig --level nginx on
    ## start
    service nginx start
    sleep 3

## check proc
    proc_exist nginx
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "Nginx fail to start!"
    fi

## record installed tag    
    echo 'NGINX' >> ${INST_LOG}
else
    succ_msg "Nginx already installed!"
fi
