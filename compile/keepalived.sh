#!/bin/bash
## Caution : if you update your system and kernel is update to new version , you need to recompile keepalived when you use ipvsadm (lvs).
if ! grep '^KEEPALIVED$' ${INST_LOG} > /dev/null 2>&1 ;then

## check proc
    proc_exist keepalived
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "KeepAlived is running on this host!"
    fi

warn_msg "\n=========================================================="
warn_msg "             KeepAlived with LVS CAUTION !                "
warn_msg "If you update Linux kernel to a new version. You have to"
warn_msg "recompile keepalived if you use ipvsadm (LVS)!"
warn_msg "============================================================\n"
read -p "Press any key to continue."

## handle source packages
    file_proc ${KEEPALIVED_SRC}
    get_file
    unpack

    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR}"

    OPENSSL_SYMLINK=$(readlink -f /usr/local/openssl)
    OPENSSL_DIR=${OPENSSL_SYMLINK:-/usr/local/openssl}

    ZLIB_SYMLINK=$(readlink -f /usr/local/zlib)
    ZLIB_DIR=${ZLIB_SYMLINK:-/usr/local/zlib}

    LDFLAGS="-L${ZLIB_DIR}/lib -L${OPENSSL_DIR}/lib -Wl,-rpath,${ZLIB_DIR}/lib -Wl,-rpath,${OPENSSL_DIR}/lib"
    CPPFLAGS="-I${ZLIB_DIR}/include -I${OPENSSL_DIR}/include"
        
## for compile
    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/keepalived'
    compile

    rm -rf ${INST_DIR}/${SRC_DIR}/etc/*
    
## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    KA_ROLE_TMP=0
    while [ ${KA_ROLE_TMP} -eq 0 ]; do
        warn_msg "\n==========================="
        warn_msg "KeepAlived Server Type "
        warn_msg "m - Master;"
        warn_msg "s - Standby;"
        warn_msg "===========================\n"
        read -p "Select m or s:" KA_ROLE
        if [ $KA_ROLE = 'm' 2>/dev/null ]; then
            install -m 0644 ${TOP_DIR}/conf/keepalived/keepalived-master.conf ${INST_DIR}/${SRC_DIR}/etc/keepalived.conf
            KA_ROLE_TMP=1
        elif [ $KA_ROLE = 's' 2>/dev/null ]; then
            install -m 0644 ${TOP_DIR}/conf/keepalived/keepalived-standby.conf ${INST_DIR}/${SRC_DIR}/etc/keepalived.conf
            KA_ROLE_TMP=1
        else
            warn_msg "Invalid option. Type m or s to continue."
        fi
    done
    ## config
    sed -i "s#.*tmp_interface.*#    interface $NIC_WAN#" ${INST_DIR}/${SRC_DIR}/etc/keepalived.conf
    sed -i "s#.*lvs_sync_daemon_interface.*#    lvs_sync_daemon_interface $NIC_WAN#" ${INST_DIR}/${SRC_DIR}/etc/keepalived.conf
    ## init scripts
    install -m 0755 ${TOP_DIR}/conf/keepalived/keepalived.init /etc/init.d/keepalived
    chkconfig --add keepalived
    chkconfig --level 35 keepalived on
    ## start
    service keepalived start
    sleep 3

## check proc
    proc_exist keepalived
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "KeepAlived fail to start!"
    fi

## record installed tag
    echo 'KEEPALIVED' >> ${INST_LOG}
else
    succ_msg "KeepAlived already installed!"
fi
