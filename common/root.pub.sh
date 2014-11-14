#!/bin/bash
if ! grep '^ROOT_PUB$' ${INST_LOG} > /dev/null 2>&1 ;then
    ## .ssh dir
    if [ -f ${TOP_DIR}/etc/rsa_public_keys/root.pub ];then
        [ ! -d "/root/.ssh" ] && mkdir -m 0700 -p /root/.ssh
        ## authorized_keys file
        [ ! -f "/root/.ssh/authorized_keys" ] && touch -m 0600 /root/.ssh/authorized_keys
        install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/root.pub /root/.ssh/authorized_keys
    else
        warn_msg "WARNING!"
        warn_msg "The SSH RSA public key for root was NOT found!"
        warn_msg "You may need to put public key file into /root/.ssh after installation."
        read -p "Press any key to continue."
    fi
## record installed tag
    echo 'ROOT_PUB' >> ${INST_LOG}
fi
