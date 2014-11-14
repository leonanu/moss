#!/bin/bash
#### redis-2.8.x
if ! grep '^REDIS$' ${INST_LOG} > /dev/null 2>&1 ;then

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
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## user add
    id redis >/dev/null 2>&1 || useradd redis -u 1003 -M -s /sbin/nologin -d ${RDS_DATA_DIR}
    ## data dir
    [ ! -d "${RDS_DATA_DIR}" ] && mkdir -m 0755 -p ${RDS_DATA_DIR}
    chown redis:redis -R ${RDS_DATA_DIR}
    ## conf
    RD_ROLE_TMP=0
    while [ ${RD_ROLE_TMP} == 0 ]; do
        warn_msg "\n==========================="
        warn_msg "Redis Server Type "
        warn_msg "m - Master;"
        warn_msg "s - Slave;"
        warn_msg "===========================\n"
        read -p "Select m or s:" RD_ROLE
        if [ $RD_ROLE == m 2>/dev/null ]; then
            install -m 0644 ${TOP_DIR}/conf/redis/redis-master.conf ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#logfile.*#logfile $RDS_DATA_DIR/redis.log#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#dir.*#dir $RDS_DATA_DIR#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            RD_ROLE_TMP=1
        elif [ $RD_ROLE == s 2>/dev/null ]; then
            install -m 0644 ${TOP_DIR}/conf/redis/redis-slave.conf ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#logfile.*#logfile $RDS_DATA_DIR/redis.log#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#dir.*#dir $RDS_DATA_DIR#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            sed -i "s#slaveof.*#slaveof ${RDS_MASTER_IP} 6379#" ${INST_DIR}/${SRC_DIR}/etc/redis.conf
            RD_ROLE_TMP=1
        else
            warn_msg "Invalid option. Type m or s to continue."
        fi
    done
    ## init scripts
    install -m 0755 ${TOP_DIR}/conf/redis/redis.init /etc/init.d/redis
    chkconfig --add redis
    chkconfig --level 35 redis on
    ## start
    service redis start
    unset SYMLINK

## record installed tag
    echo 'REDIS' >> ${INST_LOG}
else
    succ_msg "Redis already installed!"
fi
