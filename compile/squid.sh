#!/bin/bash
##squid 2.7

if ! grep '^SQUID$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${SQUID_SRC}
    get_file
    unpack

    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR} \
    --enable-xmalloc-statistics \
    --disable-carp \
    --enable-async-io=8 \
    --enable-storeio=aufs,diskd,coss,null,ufs \
    --enable-removal-policies=lru,heap \
    --enable-icmp \
    --enable-delay-pools \
    --enable-useragent-log \
    --enable-useragent-log \
    --disable-wccp \
    --disable-wccpv2 \
    --enable-kill-parent-hack \
    --enable-forward-log \
    --enable-multicast-miss \
    --enable-snmp \
    --enable-coss-aio-ops \
    --disable-select \
    --disable-poll \
    --enable-epoll \
    --disable-kqueue \
    --enable-ipf-transparent \
    --enable-large-cache-files \
    --enable-default-hostsfile=/etc/hosts \
    --enable-auth \
    --enable-x-accelerator-vary \
    --enable-follow-x-forwarded-for \
    --enable-default-err-language=Simplify_Chinese \
    --enable-err-languages=Simplify_Chinese \
    --with-maxfd=65535 \
    --with-large-files"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/squid'
    compile

## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## user add
    id squid >/dev/null 2>&1 || useradd squid -u 1004 -M -s /sbin/nologin
    ## cache dir
    [ ! -d "${SQD_CACHE_DIR}" ] && mkdir -m 0755 -p ${SQD_CACHE_DIR}
    [ ! -d "${INST_DIR}/${SRC_DIR}/var/run" ] && mkdir -m 0755 -p ${INST_DIR}/${SRC_DIR}/var/run
    chown -R squid:squid ${SQD_CACHE_DIR}
    chown -R squid:squid ${INST_DIR}/${SRC_DIR}
    ## conf
    install -m 0644 ${TOP_DIR}/conf/squid/squid.conf ${INST_DIR}/${SRC_DIR}/etc/squid.conf
    sed -i "s#cache_dir.*#cache_dir aufs ${SQD_CACHE_DIR} 4096 16 256#" ${INST_DIR}/${SRC_DIR}/etc/squid.conf
    sed -i "s#cache_mgr.*#cache_mgr ${SQD_EMAIL}#" ${INST_DIR}/${SRC_DIR}/etc/squid.conf
    sed -i "s#visible_hostname.*#visible_hostname ${SQD_VHOSTNAME}#" ${INST_DIR}/${SRC_DIR}/etc/squid.conf
    sed -i "s#cache_peer .*#cache_peer ${SQD_VIP} parent 80 0 no-query originserver name=host1#" ${INST_DIR}/${SRC_DIR}/etc/squid.conf
    sed -i "s#cache_peer_domain.*#cache_peer_domain host1 ${NGX_HOSTNAME}#" ${INST_DIR}/${SRC_DIR}/etc/squid.conf
    ## initial cache dir
    ${INST_DIR}/${SRC_DIR}/sbin/squid -z
    ## init scripts
    install -m 0744 ${TOP_DIR}/conf/squid/squid.init /etc/init.d/squid
    chkconfig --add squid
    chkconfig --level 35 squid on
    ## start
    service squid start
    
## record installed tag
    echo 'SQUID' >> ${INST_LOG}
else
    succ_msg "Squid already installed!"
fi
