#!/bin/bash
if ! grep '^ROOT_PUB$' ${INST_LOG} > /dev/null 2>&1 ;then
    ## .ssh dir
    if [ -f ${TOP_DIR}/etc/rsa_public_keys/root.pub ];then
        [ ! -d "/root/.ssh" ] && mkdir -m 0700 -p /root/.ssh
        install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/root.pub /root/.ssh/authorized_keys
        chown -R root:root /root/.ssh
    else
        warn_msg "WARNING!"
        warn_msg "The SSH RSA public key for root was NOT found!"
        warn_msg "You may need to put public key file into /root/.ssh after installation."
        read -p "Press any key to continue."
    fi
    ## log installed tag
    echo 'ROOT_PUB' >> ${INST_LOG}
fi
