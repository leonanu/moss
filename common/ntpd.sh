#!/bin/bash

## NTP Server
if ! grep '^NTP_SERVER$' ${INST_LOG} > /dev/null 2>&1 ;then
    succ_msg "Begin to configure NTP server..."
    install -m 0644 ${TOP_DIR}/conf/ntp/ntp_server.conf /etc/ntp.conf
    sed -i "s#restrict 10.*#restrict ${LAN_RANGE} mask ${LAN_MASK} nomodify#" /etc/ntp.conf
    /etc/rc.d/init.d/ntpd restart
    chkconfig --level 3 ntpd on
    succ_msg "NTP server has been configured!"
    ## log installed tag    
    echo 'NTP_SERVER' >> ${INST_LOG}
else
    succ_msg "NTP server already configured!"
fi
