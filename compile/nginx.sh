#!/bin/bash
## nginx-1.2.x
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

    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR} \
    --pid-path=/var/run/nginx.pid \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --with-file-aio \
    --with-http_ssl_module \
    --with-http_spdy_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_split_clients_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    --without-http_memcached_module \
    --without-mail_pop3_module \
    --without-mail_imap_module \
    --without-mail_smtp_module \
    --http-client-body-temp-path=/usr/local/nginx/var/tmp/client_body \
    --http-proxy-temp-path=/usr/local/nginx/var/tmp/proxy \
    --http-fastcgi-temp-path=/usr/local/nginx/var/tmp/fastcgi \
    --with-pcre"

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
    [ ! -d "${INST_DIR}/${SRC_DIR}/var/tmp/client_body" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/var/tmp/client_body
    [ ! -d "${INST_DIR}/${SRC_DIR}/var/tmp/fastcgi" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/var/tmp/fastcgi
    [ ! -d "${INST_DIR}/${SRC_DIR}/var/tmp/proxy" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/var/tmp/proxy
    chown -R www:www ${INST_DIR}/${SRC_DIR}/var
    ## conf
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.conf ${INST_DIR}/${SRC_DIR}/conf/nginx.conf
    install -m 0644 ${TOP_DIR}/conf/nginx/vhost.conf ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_server_name.*#server_name    ${NGX_HOSTNAME};#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_root.*#    root    ${NGX_DOCROOT};#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_access_log.*#    access_log    ${NGX_LOGDIR}/access.log moss buffer=4k;#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_error_log.*#    error_log    ${NGX_LOGDIR}/error.log error;#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*ng_fastcgi_param.*#        fastcgi_param    SCRIPT_FILENAME    ${NGX_DOCROOT}\$fastcgi_script_name;#" ${INST_DIR}/${SRC_DIR}/conf/vhosts/${NGX_HOSTNAME}.conf
    ## Vim syntax hilight
    VIM_SHARE_DIR=$(ls /usr/share/vim | grep 'vim7')
    install -m 0644 ${TOP_DIR}/conf/nginx/nginx.vim /usr/share/vim/${VIM_SHARE_DIR}/syntax/nginx.vim
    cat ${TOP_DIR}/conf/nginx/nginx.filetype >> /usr/share/vim/${VIM_SHARE_DIR}/filetype.vim
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
    chkconfig --level 35 nginx on
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
