#!/bin/bash
if ! grep '^REDIS$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist redis
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "Redis is running on this host!"
    fi

## handle source packages
    file_proc ${REDIS_SRC}
    get_file
    unpack

## for compile
    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/redis'
    sed -ri "s#^PREFIX.*#PREFIX=${INST_DIR}/${SRC_DIR}#" ${STORE_DIR}/${SRC_DIR}/src/Makefile
    compile
    
    mkdir ${INST_DIR}/${SRC_DIR}/etc

## for install config files
    SYMLINK='/usr/local/redis'
    RDS_PASS=$(mkpasswd -s 0 -l 12)
    echo ${RDS_PASS} > /root/.moss/redis.pass
    chmod 600 /root/.moss/redis.pass
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## user add
    id redis >/dev/null 2>&1 || useradd redis -u 1003 -M -s /sbin/nologin -d ${RDS_DATA_DIR}
    ## data dir
    [ ! -d ${RDS_DATA_DIR} ] && mkdir -m 0755 -p ${RDS_DATA_DIR}
    chown redis:redis -R ${RDS_DATA_DIR}
    ## log dir
    [ ! -d '/var/log/redis' ] && mkdir -m 0755 -p /var/log/redis
    chown redis:redis -R /var/log/redis
    ## conf
    RD_ROLE_TMP=0
    while [ ${RD_ROLE_TMP} -eq 0 ]; do
        warn_msg "\n==========================="
        warn_msg "Redis Server Type "
        warn_msg "m - Master;"
        warn_msg "s - Slave;"
        warn_msg "===========================\n"
        read -p "Select m or s:" RD_ROLE
        if [ $RD_ROLE = 'm' 2>/dev/null ]; then
            install -m 0600 ${TOP_DIR}/conf/redis/redis-master.conf ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#dir.*#dir $RDS_DATA_DIR#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#requirepass.*#requirepass ${RDS_PASS}#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            RD_ROLE_TMP=1
        elif [ $RD_ROLE = 's' 2>/dev/null ]; then
            install -m 0600 ${TOP_DIR}/conf/redis/redis-slave.conf ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#dir.*#dir $RDS_DATA_DIR#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#slaveof.*#slaveof ${RDS_MASTER_IP} 6379#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#masterauth.*#masterauth ${RDS_PASS}#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            RD_ROLE_TMP=1
        else
            warn_msg "Invalid option. Type m or s to continue."
        fi
    done
    ## THP
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    echo 'echo never > /sys/kernel/mm/transparent_hugepage/enabled' >> /etc/rc.local
    ## init scripts
    install -m 0700 ${TOP_DIR}/conf/redis/redis.init /etc/init.d/redis
    sed -i "s#REDISPASS=.*#REDISPASS=${RDS_PASS}#" /etc/init.d/redis
    chkconfig --add redis
    chkconfig --level redis on
    ## start
    service redis start
    sleep 3
    unset SYMLINK

## check proc
    proc_exist redis
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "Redis fail to start!"
    fi

## record installed tag
    echo 'REDIS' >> ${INST_LOG}
else
    succ_msg "Redis already installed!"
fi
