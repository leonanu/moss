#!/bin/bash
if ! grep '^VARNISH$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${VARNISH_SRC}
    get_file
    unpack

## for compile
    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR} \
                        --with-pcre-config=/usr/local/pcre/bin/pcre-config"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/varnish'
    compile

## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"
    ## user add
    id varnish >/dev/null 2>&1 || useradd varnish -u 1005 -M -s /sbin/nologin
    ## conf
    install -m 0644 ${TOP_DIR}/conf/varnish/varnish.conf ${INST_DIR}/${SRC_DIR}/etc/varnish/varnish.conf
    install -m 0644 ${TOP_DIR}/conf/varnish/varnish.vcl ${INST_DIR}/${SRC_DIR}/etc/varnish/varnish.vcl
    install -m 0644 ${TOP_DIR}/conf/varnish/backends.vcl ${INST_DIR}/${SRC_DIR}/etc/varnish/backends.vcl
    sed -i "s#^VARNISH_STORAGE_FILE.*#VARNISH_STORAGE_FILE=${VNS_CACHE_FILE}#" ${INST_DIR}/${SRC_DIR}/etc/varnish/varnish.conf
    sed -i "s#if (req\.http\.host.*#if (req.http.host == \"${NGX_HOSTNAME}\") {#" ${INST_DIR}/${SRC_DIR}/etc/varnish/varnish.vcl
    sed -i "s#\.host.*#.host = \"${VNS__VIP}\";#" ${INST_DIR}/${SRC_DIR}/etc/varnish/backends.vcl
    # reload script
    install -m 0744 ${TOP_DIR}/conf/varnish/varnishreload ${INST_DIR}/${SRC_DIR}/bin/varnishreload
    # init script
    install -m 0744 ${TOP_DIR}/conf/varnish/varnishd.init /etc/init.d/varnishd
    chkconfig --add varnishd
    chkconfig --level 35 varnishd on
    # start
    service varnishd start

## record installed tag
    echo 'VARNISH' >> ${INST_LOG}
else
    succ_msg "Varnish already installed!"
fi
