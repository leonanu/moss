#!/bin/bash
if ! grep '^PECL_XHPROF$' ${INST_LOG} > /dev/null 2>&1 ;then

IS_XHPROF=1
## handle source packages
    file_proc ${PECL_XHPROF_SRC}
    get_file
    unpack

## find php installed dir
    PHP_SYMLINK=$(readlink -f /usr/local/php)
    PHP_DIR=${PHP_SYMLINK:-/usr/local/php}
    
    PRE_CONFIG="${PHP_DIR}/bin/phpize"
    CONFIG="./configure --enable-redis --with-php-config=${PHP_DIR}/bin/php-config"
    MAKE='make'
    INSTALL='install -s -m 0755 modules/xhprof.so ${PHP_DIR}/ext'
    compile
    cat ${TOP_DIR}/conf/php/xhprof.ini >> /usr/local/php/etc/php.ini
    cat ${TOP_DIR}/conf/nginx/xhprof.conf >> /usr/local/nginx/conf/vhosts/${NGX_HOSTNAME}.conf

## config xhprof
    # copy xhprof files
    cp -r ${TOP_DIR}/conf/pecl_xhprof/xhprof_html ${NGX_DOCROOT}
    cp -r ${TOP_DIR}/conf/pecl_xhprof/xhprof_lib ${NGX_DOCROOT}
    [ ! -d ${NGX_DOCROOT}/xhprof_data ] && mkdir -p ${NGX_DOCROOT}/xhprof_data
    chown -R www:www ${NGX_DOCROOT}
    # config php.ini
    sed -i "s#xhprof\.output_dir.*#xhprof.output_dir=${NGX_DOCROOT}/xhprof_data#" /usr/local/php/etc/php.ini
    # config Nginx
    sed -i "s#.*xh_server_name.*#    server_name  ${NGX_XH_HOSTNAME};#" /usr/local/nginx/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*xh_root.*#        root        ${NGX_DOCROOT};#" /usr/local/nginx/conf/vhosts/${NGX_HOSTNAME}.conf
    sed -i "s#.*xh_fastcgi_param.*#        fastcgi_param  SCRIPT_FILENAME  ${NGX_DOCROOT}\$fastcgi_script_name;#" /usr/local/nginx/conf/vhosts/${NGX_HOSTNAME}.conf
    service nginx restart
    service php-fpm restart
 
## record installed tag    
    echo 'PECL_XHPROF' >> ${INST_LOG}
else
    succ_msg "PECL-Xhprof already installed!"
fi
unset IS_XHPROF
