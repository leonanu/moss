#!/bin/bash
if ! grep '^CURL$' ${INST_LOG} > /dev/null 2>&1 ;then

## handle source packages
    file_proc ${CURL_SRC}
    get_file
    unpack

## get dependent library dir
    CARES_SYMLINK=$(readlink -f /usr/local/c-ares)
    CARES_DIR=${CARES_SYMLINK:-/usr/local/c-ares}

    OPENSSL_SYMLINK=$(readlink -f /usr/local/openssl)
    OPENSSL_DIR=${OPENSSL_SYMLINK:-/usr/local/openssl}

    ZLIB_SYMLINK=$(readlink -f /usr/local/zlib)
    ZLIB_DIR=${ZLIB_SYMLINK:-/usr/local/zlib}

## use ldflags and cppflags for compile and link
    LDFLAGS="-L${ZLIB_DIR}/lib -L${OPENSSL_DIR}/lib -L${CARES_DIR}/lib -Wl,-rpath,${ZLIB_DIR}/lib -Wl,-rpath,${OPENSSL_DIR}/lib -Wl,-rpath,${CARES_DIR}/lib"
    CFLAGS="-I${ZLIB_DIR}/include -I${OPENSSL_DIR}/include -I${CARES_DIR}/include"
    CPPFLAGS="-I${ZLIB_DIR}/include -I${OPENSSL_DIR}/include -I${CARES_DIR}/include"

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
    --with-ssl=${OPENSSL_DIR} \
    --with-zlib=${ZLIB_DIR} \
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
