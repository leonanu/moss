#!/bin/bash

## check Moss log file
if [ ! -f "${INST_LOG}" ];then
    warn_msg "${INST_LOG} not found!"
    warn_msg "Maybe you did not install Moss on your system!"
    fail_msg "Quit Moss uninstallation!"
fi

## uninstall Redis
if grep '^REDIS$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you want to remove Redis?' 'n'
    DEL_REDIS=${USER_INPUT}

    if [ "${DEL_REDIS}" = 'y' ];then
        succ_msg "\nStarting Uninstall Redis...\n"

        y_or_n 'Do you wish to keep Redis database?' 'y'
        BAK_REDIS_DATA=${USER_INPUT}

        warn_msg "Stop Redis..."
        /etc/init.d/redis stop
        sleep 3
        if (pstree | grep redis > /dev/null 2>&1) ; then
            fail_msg "Redis Fail to Stop!"
        else
            succ_msg "Redis Stoped!"
        fi

        rm -f /usr/local/redis
        rm -rf ${INST_DIR}/redis-*
        rm -rf /var/log/redis

        if [ "${BAK_REDIS_DATA}" = 'n' ];then
            rm -rf ${RDS_DATA_DIR}
        else
            warn_msg "Redis database keeped in ${RDS_DATA_DIR}"
        fi

        rm -rf /var/log/redis

        chkconfig --del redis
        rm -f /etc/init.d/redis

        userdel -r redis 2>/dev/null

        sed -i "/^REDIS$/d" ${INST_LOG}

        succ_msg "Redis has been removed from your system!"
        sleep 3
    fi
fi

## uninstall MySQL
if grep '^MYSQL$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you want to remove MySQL?' 'n'
    DEL_MYSQL=${USER_INPUT}

    if [ "${DEL_MYSQL}" = 'y' ];then
        succ_msg "\nStarting Uninstall MySQL Server...\n"

        y_or_n 'Do you wish to keep MySQL database?' 'y'
        BAK_MYSQL_DATA=${USER_INPUT}

        y_or_n 'Do you wish to keep MySQL my.cnf?' 'y'
        BAK_MYSQL_CONF=${USER_INPUT}

        y_or_n 'Do you wish to keep MySQL database backup?' 'y'
        BAK_MYSQL_BACK=${USER_INPUT}

        warn_msg "Stop MySQL Server..."
        /etc/init.d/mysqld stop
        sleep 3
        if (pstree | grep mysqld > /dev/null 2>&1) ; then
            fail_msg "MySQL Server Fail to Stop!"
        else
            succ_msg "MySQL Server Stoped!"
        fi

        rm -f /usr/local/mysql
        rm -rf ${INST_DIR}/Percona-Server-*
        rm -rf ${INST_DIR}/mysql-*
        rm -f /usr/local/percona-xtrabackup
        rm -rf ${INST_DIR}/percona-xtrabackup-*
        rm -rf /var/log/mysql
        rm -f /usr/local/bin/xtrabackup.sh
        rm -f /usr/local/etc/logrotate/mysql
        sed -i "/.*# Logrotate - MySQL.*/d" /var/spool/cron/root
        sed -i "/.*\/usr\/local\/etc\/logrotate\/mysql.*/d" /var/spool/cron/root
        sed -i "/.*# MySQL Backup.*/d" /var/spool/cron/root
        sed -i "/.*\/usr\/local\/bin\/xtrabackup\.sh.*/d" /var/spool/cron/root

        if [ "${BAK_MYSQL_DATA}" = 'n' ];then
            rm -rf ${MYSQL_DATA_DIR}
        else
            warn_msg "MySQL database keeped in ${MYSQL_DATA_DIR}"
        fi

        if [ "${BAK_MYSQL_CONF}" = 'n' ];then
            rm -f /etc/my.cnf
        else
            warn_msg "MySQL my.cnf keeped in /etc/my.cnf"
        fi

        if [ "${BAK_MYSQL_BACK}" = 'n' ];then
            rm -f ${XTRABACKUP_BACKUP_DIR}
        else
            warn_msg "MySQL database backup keeped in ${XTRABACKUP_BACKUP_DIR}"
        fi

        chkconfig --del mysqld
        rm -f /etc/init.d/mysqld

        rm -f /root/.my.cnf
        rm -f /root/.mysql_history

        userdel -r mysql 2>/dev/null

        sed -i "/^MYSQL$/d" ${INST_LOG}
        sed -i "/^XTRABACKUP$/d" ${INST_LOG}

        succ_msg "MySQL Server has been removed from your system!"
        sleep 3
    fi
fi

## uninstall Nginx
if grep '^NGINX$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove Nginx?' 'n'
    DEL_NGINX=${USER_INPUT}

    if [ "${DEL_NGINX}" = 'y' ];then
        succ_msg "\nStarting Uninstall Nginx...\n"

        y_or_n 'Do you wish to keep Nginx document root?' 'y'
        BAK_NGINX_DOCROOT=${USER_INPUT}

        y_or_n 'Do you wish to keep Nginx logs?' 'y'
        BAK_NGINX_LOG=${USER_INPUT}

        warn_msg "Stop Nginx..."
        /etc/init.d/nginx stop
        sleep 3
        if (pstree | grep nginx > /dev/null 2>&1) ; then
            fail_msg "Nginx Fail to Stop!"
        else
            succ_msg "Nginx Stoped!"
        fi

        rm -f /usr/local/nginx
        rm -rf ${INST_DIR}/nginx-*
        rm -rf ${INST_DIR}/tengine-*
        rm -rf /var/log/nginx
        rm -f /usr/local/etc/logrotate/nginx
        sed -i "/.*# Logrotate - Nginx.*/d" /var/spool/cron/root
        sed -i "/.*\/usr\/local\/etc\/logrotate\/nginx.*/d" /var/spool/cron/root

        if [ "${BAK_NGINX_DOCROOT}" = 'n' ];then
            rm -rf ${NGX_DOCROOT}
        else
            warn_msg "Nginx WEB site documents keeped in ${NGX_DOCROOT}"
        fi

        if [ "${BAK_NGINX_LOG}" = 'n' ];then
            rm -rf ${NGX_LOGDIR}
        else
            warn_msg "Nginx logs keeped in ${NGX_LOGDIR}"
        fi

        chkconfig --del nginx
        rm -f /etc/init.d/nginx

        if (pstree | grep php-fpm > /dev/null 2>&1) ; then
            warn_msg "User www is used by PHP-FPM now."
            warn_msg "Moss will not delete www user."
        else
            userdel -r www 2>/dev/null
        fi

        sed -i "/^NGINX$/d" ${INST_LOG}

        succ_msg "Nginx has been removed from your system!"
        sleep 3
    fi
fi

## uninstall PHP
if grep '^PHP$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove PHP?' 'n'
    DEL_PHP=${USER_INPUT}

    if [ "${DEL_PHP}" = 'y' ];then
        succ_msg "\nStarting Uninstall PHP...\n"

        y_or_n 'Do you wish to keep PHP logs?' 'y'
        BAK_PHP_LOG=${USER_INPUT}

        warn_msg "Stop PHP-FPM..."
        /etc/init.d/php-fpm stop
        sleep 3
        if (pstree | grep php-fpm > /dev/null 2>&1) ; then
            fail_msg "PHP-FPM Fail to Stop!"
        else
            succ_msg "PHP-FPM Stoped!"
        fi

        rm -f /usr/local/php
        rm -rf ${INST_DIR}/php-*
        rm -f /usr/local/etc/logrotate/php-fpm
        sed -i "/.*# Logrotate - PHP-FPM.*/d" /var/spool/cron/root
        sed -i "/.*\/usr\/local\/etc\/logrotate\/php-fpm.*/d" /var/spool/cron/root

        if [ "${BAK_PHP_LOG}" = 'n' ];then
            rm -rf /var/log/php
        else
            warn_msg "PHP logs keeped in /var/log/php"
        fi

        chkconfig --del php-fpm
        rm -f /etc/init.d/php-fpm

        if (pstree | grep nginx > /dev/null 2>&1) ; then
            warn_msg "User www is used by Nginx now."
            warn_msg "Moss will not delete www user."
        else
            userdel -r www 2>/dev/null
        fi

        sed -i "/^PHP$/d" ${INST_LOG}

        if grep '^PECL_MEMCACHED$' ${INST_LOG} > /dev/null 2>&1 ; then
            sed -i "/^PECL_MEMCACHED$/d" ${INST_LOG}
            succ_msg "PECL Module: Memcached Removed!"
        fi

        if grep '^PECL_MEMCACHE$' ${INST_LOG} > /dev/null 2>&1 ; then
            sed -i "/^PECL_MEMCACHE$/d" ${INST_LOG}
            succ_msg "PECL Module: Memcache Removed!"
        fi

        if grep '^PECL_REDIS$' ${INST_LOG} > /dev/null 2>&1 ; then
            sed -i "/^PECL_REDIS$/d" ${INST_LOG}
            succ_msg "PECL Module: Redis Removed!"
        fi

        if grep '^PECL_XHPROF$' ${INST_LOG} > /dev/null 2>&1 ; then
            sed -i "/^PECL_XHPROF$/d" ${INST_LOG}
            succ_msg "PECL Module: Xhprof Removed!"
        fi

        if grep '^PECL_XCACHE$' ${INST_LOG} > /dev/null 2>&1 ; then
            sed -i "/^PECL_XCACHE$/d" ${INST_LOG}
            succ_msg "PECL Module: XCache Removed!"
        fi

        succ_msg "PHP has been removed from your system!"
        sleep 3
    fi
fi

## uninstall libevent
if grep '^LIBEVENT$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove libevent?' 'n'
    DEL_LIBEVENT=${USER_INPUT}

    if [ "${DEL_LIBEVENT}" = 'y' ];then
        rm -f /usr/local/libevent
        rm -rf ${INST_DIR}/libevent-*

        sed -i "/^LIBEVENT$/d" ${INST_LOG}

        succ_msg "libevent has been removed from your system!"
        sleep 3
    fi
fi

## uninstall OpenSSL
if grep '^OPENSSL$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove OpenSSL?' 'n'
    DEL_OPENSSL=${USER_INPUT}

    if [ "${DEL_OPENSSL}" = 'y' ];then
        rm -f /usr/local/openssl
        rm -rf ${INST_DIR}/openssl-*

        sed -i "/^OPENSSL$/d" ${INST_LOG}

        succ_msg "OpenSSL has been removed from your system!"
        sleep 3
    fi
fi

## uninstall zlib 
if grep '^ZLIB$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove zlib?' 'n'
    DEL_ZLIB=${USER_INPUT}
    
    if [ "${DEL_ZLIB}" = 'y' ];then
        rm -f /usr/local/zlib
        rm -rf ${INST_DIR}/zlib-*
        
        sed -i "/^ZLIB$/d" ${INST_LOG}
        
        succ_msg "zlib has been removed from your system!"
        sleep 3
    fi  
fi

## uninstall PCRE
if grep '^PCRE$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove PCRE?' 'n'
    DEL_PCRE=${USER_INPUT}
    
    if [ "${DEL_PCRE}" = 'y' ];then
        rm -f /usr/local/pcre
        rm -rf ${INST_DIR}/pcre-*
        
        sed -i "/^PCRE$/d" ${INST_LOG}
        
        succ_msg "PCRE has been removed from your system!"
        sleep 3
    fi  
fi

## uninstall LibXML2
if grep '^LIBXML2$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove LibXML2?' 'n'
    DEL_LIBXML2=${USER_INPUT}
    
    if [ "${DEL_LIBXML2}" = 'y' ];then
        rm -f /usr/local/libxml2
        rm -rf ${INST_DIR}/libxml2-*
        
        sed -i "/^LIBXML2$/d" ${INST_LOG}
        
        succ_msg "LibXML2 has been removed from your system!"
        sleep 3
    fi  
fi

## uninstall LibXML2
if grep '^LIBXML2$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove LibXML2?' 'n'
    DEL_LIBXML2=${USER_INPUT}
    
    if [ "${DEL_LIBXML2}" = 'y' ];then
        rm -f /usr/local/libxml2
        rm -rf ${INST_DIR}/libxml2-*
        
        sed -i "/^LIBXML2$/d" ${INST_LOG}
        
        succ_msg "LibXML2 has been removed from your system!"
        sleep 3
    fi  
fi

## uninstall LibMcrypt
if grep '^LIBMCRYPT$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove LibMcrypt?' 'n'
    DEL_LIBMCRYPT=${USER_INPUT}

    if [ "${DEL_LIBMCRYPT}" = 'y' ];then
        rm -f /usr/local/libmcrypt
        rm -rf ${INST_DIR}/libmcrypt-*

        sed -i "/^LIBMCRYPT$/d" ${INST_LOG}

        succ_msg "LibMcrypt has been removed from your system!"
        sleep 3
    fi
fi

## uninstall LibMemcached
if grep '^LIBMEMCACHED$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove LibMemcached?' 'n'
    DEL_LIBMEMCACHED=${USER_INPUT}

    if [ "${DEL_LIBMEMCACHED}" = 'y' ];then
        rm -f /usr/local/libmemcached
        rm -rf ${INST_DIR}/libmemcached-*

        sed -i "/^LIBMEMCACHED$/d" ${INST_LOG}

        succ_msg "LibMemcached has been removed from your system!"
        sleep 3
    fi
fi

## uninstall CURL
if grep '^CURL$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove CURL?' 'n'
    DEL_CURL=${USER_INPUT}
    
    if [ "${DEL_CURL}" = 'y' ];then
        rm -f /usr/local/curl
        rm -rf ${INST_DIR}/curl-*
        
        sed -i "/^CURL$/d" ${INST_LOG}
        
        succ_msg "CURL has been removed from your system!"
        sleep 3
    fi  
fi

## uninstall C-Ares
if grep '^CARES$' ${INST_LOG} > /dev/null 2>&1 ; then
    y_or_n 'Do you wish to remove C-Ares?' 'n'
    DEL_CARES=${USER_INPUT}
    
    if [ "${DEL_CARES}" = 'y' ];then
        rm -f /usr/local/c-ares
        rm -rf ${INST_DIR}/c-ares-*
        
        sed -i "/^CARES$/d" ${INST_LOG}
        
        succ_msg "C-Ares has been removed from your system!"
        sleep 3
    fi  
fi
