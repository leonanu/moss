#!/bin/bash

## set hostname
if ! grep '^SET_HOSTNAME' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ ! -z "${OS_HOSTNAME}" ];then
        OLD_HOSTNAME=$(hostname)
        hostname "${OS_HOSTNAME}"
        sed -i "s/HOSTNAME=.*/HOSTNAME=${OS_HOSTNAME}/g" /etc/sysconfig/network
        if [ -n "$(grep "$OLD_HOSTNAME" /etc/hosts)" ]; then
            sed -i "s/${OLD_HOSTNAME}//g" /etc/hosts
        fi
        sed -i "s/127\.0\.0\.1.*/127.0.0.1    ${OS_HOSTNAME} localhost localhost.localdomain/" /etc/hosts
    fi
    ## log installed tag
    echo 'SET_HOSTNAME' >> ${INST_LOG}
fi

# set /etc/resolv.conf
if ! grep '^SET_RESOLV' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'timeout' /etc/resolv.conf > /dev/null 2>&1 ;then
        sed -i '1i\options timeout:1 attempts:1 rotate' /etc/resolv.conf
    fi
    ## log installed tag
    echo 'SET_RESOLV' >> ${INST_LOG}
fi

# display boot message
cp /boot/grub/grub.conf /boot/grub/grub.conf.ori
sed -i 's/rhgb//g' /boot/grub/grub.conf
sed -i 's/quiet//g' /boot/grub/grub.conf

## selinux
if ! grep '^SET_SELINUX' ${INST_LOG} > /dev/null 2>&1 ;then
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config 
    setenforce 0
    ## log installed tag
    echo 'SET_SELINUX' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## bashrc settings
if ! grep '^SET_BASHRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss bashrc' /etc/bashrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/bash/bashrc >> /etc/bashrc
    fi
    ## log installed tag
    echo 'SET_BASHRC' >> ${INST_LOG}
fi

## vimrc settings
if ! grep '^SET_VIMRC' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss vimrc' /etc/vimrc > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/vi/vimrc >> /etc/vimrc
    fi
    ## log installed tag
    echo 'SET_VIMRC' >> ${INST_LOG}
fi
    
## ntp client
if ! grep '^SET_NTP' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/ntp/ntp_client.conf /etc/ntp.conf
    if ! grep 'Moss Time Sync' /var/spool/cron/root > /dev/null 2>&1 ;then 
        echo '' >> /var/spool/cron/root
        echo '# Moss Time Sync' >> /var/spool/cron/root
        echo '0 * * * * /usr/sbin/ntpdate cn.pool.ntp.org > /dev/null 2>&1;/sbin/hwclock -w > /dev/null 2>&1' >> /var/spool/cron/root
        chown root:root /var/spool/cron/root
        chmod 600 /var/spool/cron/root
        /etc/rc.d/init.d/ntpd stop
        chkconfig ntpd off
    fi
    ## log installed tag
    echo 'SET_NTP' >> ${INST_LOG}
fi

## set root password
if [ ! -z "${OS_ROOT_PASSWD}" ];then
    if ! grep '^SET_ROOT_PASSWORD' ${INST_LOG} > /dev/null 2>&1 ;then
        echo ${OS_ROOT_PASSWD} | passwd --stdin root
        ## log installed tag
        echo 'SET_ROOT_PASSWORD' >> ${INST_LOG}
    fi
fi

## %wheel users
if ! grep '^ADD_USER_WHEEL' ${INST_LOG} > /dev/null 2>&1 ;then
    if [ -n "${GROUP_WHEEL}" ];then
        for ADD_USER_WHEEL in ${GROUP_WHEEL};do
            id ${ADD_USER_WHEEL} >/dev/null 2>&1 || useradd -u ${USER_WHEEL_FROM} -G wheel ${ADD_USER_WHEEL}
            if [ ! -f /home/${ADD_USER_WHEEL}/.passwd ];then
                TMP_PASS=$(mkpasswd -s 0 -l 10)
                echo ${TMP_PASS} | passwd --stdin ${ADD_USER_WHEEL}
                echo ${TMP_PASS} > /home/${ADD_USER_WHEEL}/.passwd
                chown root:root /home/${ADD_USER_WHEEL}/.passwd
                chmod 400 /home/${ADD_USER_WHEEL}/.passwd
            fi
            if [ ! -d /home/${ADD_USER_WHEEL}/.ssh ];then
                mkdir -m 0700 /home/${ADD_USER_WHEEL}/.ssh
                if [ ${ADD_USER_WHEEL} != moss ];then
                    if [ -f ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_WHEEL}.pub ];then
                        install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_WHEEL}.pub /home/${ADD_USER_WHEEL}/.ssh/authorized_keys
                    fi
                fi
                chown ${ADD_USER_WHEEL}:${ADD_USER_WHEEL} -R /home/${ADD_USER_WHEEL}/.ssh
            fi
            USER_WHEEL_FROM=$(expr ${USER_WHEEL_FROM} + 1)
        done
    fi
    ## log installed tag
    echo 'ADD_USER_WHEEL' >> ${INST_LOG}
fi

## %sa users
if ! grep '^ADD_USER_SA' ${INST_LOG} > /dev/null 2>&1 ;then
    groupadd sa -g 3000
    if [ -n "${GROUP_SA}" ];then
        for ADD_USER_SA in ${GROUP_SA};do
            id ${ADD_USER_SA} >/dev/null 2>&1 || useradd -u ${USER_SA_FROM} -G wheel ${ADD_USER_SA}
            if [ ! -f /home/${ADD_USER_SA}/.passwd ];then
                TMP_PASS=$(mkpasswd -s 0 -l 10)
                echo ${TMP_PASS} | passwd --stdin ${ADD_USER_SA}
                echo ${TMP_PASS} > /home/${ADD_USER_SA}/.passwd
                chown root:root /home/${ADD_USER_SA}/.passwd
                chmod 400 /home/${ADD_USER_SA}/.passwd
            fi
            if [ ! -d /home/${ADD_USER_SA}/.ssh ];then
                mkdir -m 0700 /home/${ADD_USER_SA}/.ssh
                if [ ${ADD_USER_SA} != moss ];then
                    if [ -f ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_SA}.pub ];then
                        install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_SA}.pub /home/${ADD_USER_SA}/.ssh/authorized_keys
                    fi
                fi
                chown ${ADD_USER_SA}:${ADD_USER_SA} -R /home/${ADD_USER_SA}/.ssh
            fi
            USER_SA_FROM=$(expr ${USER_SA_FROM} + 1)
        done
    fi
    ## log installed tag
    echo 'ADD_USER_SA' >> ${INST_LOG}
fi

## genarate Moss key pair
#if ! grep '^MOSS_KEY_PAIR' ${INST_LOG} > /dev/null 2>&1 ;then
#    ssh-keygen -t rsa -N '' -C $OS_HOSTNAME -f /home/moss/.ssh/id_rsa
#    chown -R moss.moss /home/moss/.ssh
#    chmod 400 /home/moss/.ssh/id_rsa*
#    ## log installed tag
#    echo 'MOSS_KEY_PAIR' >> ${INST_LOG}
#fi

## sudo
if ! grep '^SUDO' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0440 --backup=numbered ${TOP_DIR}/conf/sudo/sudoers /etc/sudoers
    ## log installed tag
    echo 'SUDO' >> ${INST_LOG}
fi
    
## openssh
if ! grep '^OPENSSH' ${INST_LOG} > /dev/null 2>&1 ;then
    sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config
    sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    sed -r -i 's/GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/ssh_config

    PUBKEY_NUM=$(ls -1 ${TOP_DIR}/etc/rsa_public_keys/*.pub 2>/dev/null | wc -l)
    PUBKEY_NUM_USER=$(ls -1 ${TOP_DIR}/etc/rsa_public_keys/*.pub 2>/dev/null | grep -v 'root.pub' | wc -l)

    if [ ${SSH_PASS_AUTH} -eq 0 2>/dev/null ]; then
        if [ ${PUBKEY_NUM} -eq 0 2>/dev/null ];then
            warn_msg "ERROR!"
            warn_msg "You want disable SSH password authentication."
            warn_msg "But no user SSH public key found!"
            warn_msg "You can not login system without user SSH key!"
            warn_msg "Please put user SSH RSA public keys in ${TOP_DIR}/etc/rsa_public_keys!"
            fail_msg "Moss installation terminated!"
        fi
        sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
    fi

    if [ ${SSH_ROOT_LOGIN} -eq 0 2>/dev/null ] && [ ${SSH_PASS_AUTH} -eq 0 2>/dev/null ]; then
        if [ ${PUBKEY_NUM_USER} -eq 0 2>/dev/null ];then
            warn_msg "ERROR!"
            warn_msg "You want disable root login via SSH."
            warn_msg "But no other user SSH public key found and password authentication was disabled!"
            warn_msg "You need to allow SSH password authentication or put other common user SSH public"
            warn_msg "key in ${TOP_DIR}/etc/rsa_public_keys!"
            fail_msg "Moss installation terminated!"
        fi
        sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    fi

    /etc/rc.d/init.d/sshd restart
    ## log installed tag
    echo 'OPENSSH' >> ${INST_LOG}
fi

## profiles
if ! grep '^PROFILE' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/profile/history.sh /etc/profile.d/history.sh
    install -m 0644 ${TOP_DIR}/conf/profile/path.sh /etc/profile.d/path.sh
    ## log installed tag
    echo 'PROFILE' >> ${INST_LOG}
fi
    
## sysctl
if ! grep '^SYSCTL' ${INST_LOG} > /dev/null 2>&1 ;then
    if ! grep 'Moss sysctl' /etc/sysctl.conf > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/sysctl/sysctl.conf >> /etc/sysctl.conf
        sysctl -p
    fi
    if ! grep 'ip_conntrack hashsize=' /etc/modprobe.d/openfwwf.conf > /dev/null 2>&1 ;then
        cat ${TOP_DIR}/conf/sysctl/openfwwf.conf >> /etc/modprobe.d/openfwwf.conf
    fi
    ## log installed tag
    echo 'SYSCTL' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## System Handler
if ! grep '^SYS_HANDLER' ${INST_LOG} > /dev/null 2>&1 ;then
    echo  \* soft nofile 51200 >> /etc/security/limits.conf
    echo  \* hard nofile 51200 >> /etc/security/limits.conf
    ## log installed tag
    echo 'SYS_HANDLER' >> ${INST_LOG}
    NEED_REBOOT=1
fi

## timezone
if ! grep '^TIMEZONE' ${INST_LOG} > /dev/null 2>&1 ;then
cat > /etc/sysconfig/clock <<EOF
ZONE="Asia/Shanghai"
UTC=true
ARC=false
EOF
    install -m 0755 /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    tzdata-update
    ## log installed tag
    echo 'TIMEZONE' >> ${INST_LOG}
fi

## nscd
if ! grep '^NSCD' ${INST_LOG} > /dev/null 2>&1 ;then
    install -m 0644 ${TOP_DIR}/conf/nscd/nscd.conf /etc/nscd.conf
    service nscd restart 2>/dev/null
    ## log installed tag
    echo 'NSCD' >> ${INST_LOG}
fi

## system service
if ! grep '^SYS_SERVICE' ${INST_LOG} > /dev/null 2>&1 ;then
    for SVC_ON in acpid atd auditd autofs cpuspeed crond haldaemon irqbalance messagebus network nscd portmap rsyslog sshd sysstat udev-post;do
        chkconfig $SVC_ON on 2>/dev/null
        service $SVC_ON start 2>/dev/null
    done

    for SVC_OFF in arptables_jf arpwatch ip6tables iptables ipsec kdump mdmonitor netconsole netfs nfs nfslock ntpd ntpdate postfix psacct quota_nld rdisc restorecond rngd rpcbind rpcgssd rpcsvcgssd saslauthd smartd snmpd snmptrapd svnserve winbind;do
        chkconfig $SVC_OFF off 2>/dev/null
        service  $SVC_OFF stop 2>/dev/null
    done
    ## log installed tag
    echo 'SYS_SERVICE' >> ${INST_LOG}
    NEED_REBOOT=1
fi
