#!/bin/bash
if ! grep '^CURL$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${CURL_SRC}
    get_file
    unpack

## get dependent library dir
    CARES_SYMLINK=$(readlink -f /usr/local/c-ares)
    CARES_DIR=${CARES_SYMLINK:-/usr/local/c-ares}


## use ldflags and cppflags for compile and link
    LDFLAGS="-L${CARES_DIR}/lib -Wl,-rpath,${CARES_DIR}/lib"
    CFLAGS="-I${CARES_DIR}/include"
    CPPFLAGS="-I${CARES_DIR}/include"

## compile    
    CONFIG="./configure --prefix=${INST_DIR}/${SRC_DIR} \
    --enable-optimize \
    --enable-ares=${CARES_DIR} \
    --enable-http \
    --enable-file \
    --enable-crypto-auth \
    --enable-cookies \
    --disable-debug \
    --disable-curldebug \
    --disable-static \
    --disable-ftp \
    --disable-ldap \
    --disable-ldaps \
    --disable-rtsp \
    --disable-proxy \
    --disable-dict \
    --disable-telnet \
    --disable-tftp \
    --disable-pop3 \
    --disable-imap \
    --disable-smtp \
    --disable-gopher \
    --disable-ipv6 \
    --disable-verbose \
    --disable-sspi \
    --disable-ntlm-wb \
    --disable-tls-srp \
    --without-libssh2"

    MAKE='make'
    INSTALL='make install'
    SYMLINK='/usr/local/curl'
    compile

## record installed tag
    echo 'CURL' >> ${INST_LOG}
else
    succ_msg "Curl already installed!"
fi
