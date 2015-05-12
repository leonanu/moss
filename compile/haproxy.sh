#!/bin/bash
if ! grep '^HAPROXY$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist haproxy
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "There already have HAProxy running!"
    fi

## handle source packages
    file_proc ${HAPROXY_SRC}
    get_file
    unpack

    OPENSSL_INC_SYMLINK=$(readlink -f /usr/local/openssl/include)
    OPENSSL_INC_DIR=${OPENSSL_INC_SYMLINK:-/usr/local/openssl/include}
    OPENSSL_LIB_SYMLINK=$(readlink -f /usr/local/openssl/lib)
    OPENSSL_LIB_DIR=${OPENSSL_LIB_SYMLINK:-/usr/local/openssl/lib}

    CONFIG="TARGET=linux2628 \
            ARCH=x86_64 \
            USE_ZLIB=1 \
            USE_PCRE=1 \
            USE_OPENSSL=1 \
            SSL_INC=${OPENSSL_INC_DIR} \
            SSL_LIB=${OPENSSL_LIB_DIR} \
            ADDLIB=-lz"

## for compile
    make ${CONFIG}
    make install PREFIX=${INST_DIR}/${SRC_DIR}
    mkdir -p ${INST_DIR}/${SRC_DIR}/etc
    SYMLINK='/usr/local/haproxy'
    chown -R nobody.nobody ${INST_DIR}/${SRC_DIR}
    ln -s ${INST_DIR}/${SRC_DIR} ${SYMLINK}
    
## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## config
    install -m 0644 ${TOP_DIR}/conf/haproxy/haproxy.conf ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    sed -i "s#bind.*#bind *:${HA_PORT}#" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    sed -i "s#www.foo.com#${SITE_HOSTNAME}#g" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    if [ -n "${HA_BKSRV1}" ];then
        sed -i "s#server Server1.*#server Server1 ${HA_BKSRV1} cookie Server1#" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    else
        sed -i "s#server Server1.*##" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    fi
    if [ -n "${HA_BKSRV2}" ];then
        sed -i "s#server Server2.*#server Server2 ${HA_BKSRV2} cookie Server2#" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    else
        sed -i "s#server Server2.*##" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    fi
    if [ -n "${HA_BKSRV3}" ];then
        sed -i "s#server Server3.*#server Server3 ${HA_BKSRV3} cookie Server3#" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    else
        sed -i "s#server Server3.*##" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    fi
    sed -i "s#stats auth.*#stats auth ${HA_USERNAME}:${HA_PASSWORD}#" ${INST_DIR}/${SRC_DIR}/etc/haproxy.conf
    ## init scripts
    install -m 0755 ${TOP_DIR}/conf/haproxy/haproxy.init /etc/init.d/haproxy
    chkconfig --add haproxy
    chkconfig --level 35 haproxy on
    ## start
    service haproxy start
    sleep 3
    ## check proc
    proc_exist haproxy
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "HAPrxoy fail to start"
    fi

## record installed tag
    echo 'HAPROXY' >> ${INST_LOG}
else
    succ_msg "HAPrxoy already installed!"
fi
