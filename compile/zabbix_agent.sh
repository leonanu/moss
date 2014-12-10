#!/bin/bash
if ! grep '^ZABBIX_AGENT$' ${INST_LOG} > /dev/null 2>&1 ;then

## install RPM packages depend by Zabbix
succ_msg "Install RPM packages depend by Zabbix."
yum install -y net-snmp-devel libcurl-devel OpenIPMI-devel sqlite-devel libssh2-devel

## handle source packages
    file_proc ${ZABBIX_SRC}
    get_file
    unpack

## compile
    CONFIG="./configure \
    --prefix=${INST_DIR}/${SRC_DIR} \
    --enable-agent"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/zabbix'
    compile

## for install config files
    # prepare directory
    mkdir -p /var/log/zabbix
    mkdir -p ${INST_DIR}/${SRC_DIR}/share/zabbix/ssl/{certs,keys}
    mkdir -p ${INST_DIR}/${SRC_DIR}/share/zabbix/modules
    mkdir -p ${INST_DIR}/${SRC_DIR}/share/zabbix/{alertscripts,externalscripts}
    # conf
    install -m 0644 ${TOP_DIR}/conf/zabbix_agent/zabbix_agentd.conf ${INST_DIR}/${SRC_DIR}/etc/zabbix_agent.conf
    install -m 0644 ${TOP_DIR}/conf/zabbix_agent/zabbix_agentd.conf ${INST_DIR}/${SRC_DIR}/etc/zabbix_agentd.conf 
    install -m 0644 ${TOP_DIR}/conf/zabbix_agent/mysql.conf ${INST_DIR}/${SRC_DIR}/etc/zabbix_agentd.conf.d/mysql.conf
    install -m 0644 ${TOP_DIR}/conf/zabbix_agent/nginx.conf ${INST_DIR}/${SRC_DIR}/etc/zabbix_agentd.conf.d/nginx.conf
    install -m 0755 ${TOP_DIR}/conf/zabbix_agent/mysql.sh ${INST_DIR}/${SRC_DIR}/share/zabbix/externalscripts/mysql.sh
    install -m 0755 ${TOP_DIR}/conf/zabbix_agent/nginx.sh ${INST_DIR}/${SRC_DIR}/share/zabbix/externalscripts/nginx.sh
    sed -i "s#^Server=.*#Server=$ZABBIX_SERVER_IP#" ${INST_DIR}/${SRC_DIR}/etc/zabbix_agent.conf
    sed -i "s#^Server=.*#Server=$ZABBIX_SERVER_IP#" ${INST_DIR}/${SRC_DIR}/etc/zabbix_agentd.conf
    sed -i "s#^ServerActive.*#ServerActive=$ZABBIX_SERVER_IP#" ${INST_DIR}/${SRC_DIR}/etc/zabbix_agent.conf
    sed -i "s#^ServerActive.*#ServerActive=$ZABBIX_SERVER_IP#" ${INST_DIR}/${SRC_DIR}/etc/zabbix_agentd.conf
    # init scripts
    install -m 0755 ${TOP_DIR}/conf/zabbix_agent/zabbix_agentd.init /etc/init.d/zabbix_agentd
    chkconfig --add zabbix_agentd
    chkconfig --level 3 zabbix_agentd on
    # chown
    # start
    service zabbix_agentd start
    

## record installed tag 
    echo 'ZABBIX_AGENT' >> ${INST_LOG}
else
    succ_msg "Zabbix agent already installed!"
fi
