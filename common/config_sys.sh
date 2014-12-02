#!/bin/bash

if ! grep '^CONFIG_SYS' ${INST_LOG} > /dev/null 2>&1 ;then

    ## set hostname
    SYS_HOSTNAME=$(hostname)
    if [ $OS_HOSTNAME != $SYS_HOSTNAME ]; then
        hostname $OS_HOSTNAME
        sed -i "s#HOSTNAME.*#HOSTNAME=${OS_HOSTNAME}#" /etc/sysconfig/network
        sed -i "s#127.*#& ${OS_HOSTNAME}#" /etc/hosts
    fi

    ## config system files
    ## selinux
    sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config 
    setenforce 0

    ## Vim settings
    echo "alias vi='vim'" >> /etc/bashrc
    echo "alias grep='grep --color'" >> /etc/bashrc
    echo 'syntax on' >> /etc/vimrc 
    echo 'set ruler' >> /etc/vimrc
    echo 'set nobackup' >> /etc/vimrc
    echo 'set tabstop=4' >> /etc/vimrc
    echo 'set paste' >> /etc/vimrc
    
    ## ntp
    install -m 0644 ${TOP_DIR}/conf/ntp/ntp_client.conf /etc/ntp.conf
    echo '' >> /var/spool/cron/root
    echo '# Time Sync' >> /var/spool/cron/root
    echo '*/30 * * * * /usr/sbin/ntpdate cn.pool.ntp.org;/sbin/hwclock -w > /dev/null 2>&1' >> /var/spool/cron/root
    chown root:root /var/spool/cron/root
    chmod 600 /var/spool/cron/root
    /etc/rc.d/init.d/ntpd stop

    ## DELEGATING
    echo $OS_ROOT_PASSWD | passwd --stdin root

    ## pubkey directory counting.
    PUBKEY_DIR=$(ls -l ${TOP_DIR}/etc/rsa_public_keys/*.pub 2>/dev/null| grep -v 'total' | grep -v 'root.pub' | wc -l)

    ## %wheel users
    if [ -n "${GROUP_WHEEL}" ];then
        for ADD_USER_WHEEL in ${GROUP_WHEEL};do
            id ${ADD_USER_WHEEL} >/dev/null 2>&1 || useradd -u ${USER_WHEEL_FROM} -G wheel ${ADD_USER_WHEEL}
            if [ ! -f /home/${ADD_USER_WHEEL}/.passwd ];then
                TMP_PASS=$(mkpasswd -s 0)
                echo ${TMP_PASS} | passwd --stdin ${ADD_USER_WHEEL}
                echo ${TMP_PASS} > /home/${ADD_USER_WHEEL}/.passwd
                chown root:root /home/${ADD_USER_WHEEL}/.passwd
                chmod 400 /home/${ADD_USER_WHEEL}/.passwd
            fi
            if [ ! -d /home/${ADD_USER_WHEEL}/.ssh ];then
                mkdir -m 0700 /home/${ADD_USER_WHEEL}/.ssh
                if [ -f ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_WHEEL}.pub ];then
                    install -m 0400 ${TOP_DIR}/etc/rsa_public_keys/${ADD_USER_WHEEL}.pub /home/${ADD_USER_WHEEL}/.ssh/authorized_keys
                fi
                chown ${ADD_USER_WHEEL}:${ADD_USER_WHEEL} -R /home/${ADD_USER_WHEEL}/.ssh
            fi
            USER_WHEEL_FROM=$(expr ${USER_WHEEL_FROM} + 1)
        done
    fi

    ## %sa users
    groupadd sa -g 3000
    if [ -n "${GROUP_SA}" ];then
        for ADD_USER_SA in ${GROUP_SA};do
            id ${ADD_USER_SA} >/dev/null 2>&1 || useradd -u ${USER_SA_FROM} -G wheel ${ADD_USER_SA}
            if [ ! -f /home/${ADD_USER_SA}/.passwd ];then
                TMP_PASS=$(mkpasswd -s 0)
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
    #ssh-keygen -t rsa -N '' -C $OS_HOSTNAME -f /home/moss/.ssh/id_rsa
    #chown -R moss.moss /home/moss/.ssh
    #chmod 400 /home/moss/.ssh/id_rsa*

    ## sudo
    install -m 0440 --backup=numbered ${TOP_DIR}/conf/sudo/sudoers /etc/sudoers
    
    ## openssh
    if [ ${SSH_PASS_AUTH} -eq 0 2>/dev/null ]; then
        if [ ${PUBKEY_DIR} -eq 0 ];then
            warn_msg "SSH password authentication disabled."
            warn_msg "But no users' SSH RSA public key found!"
            warn_msg "Please put users' SSH RSA public keys in ${TOP_DIR}/etc/rsa_public_keys first!"
            fail_msg "Moss installation abort!"
        fi
        sed -r -i 's/^#?PasswordAuthentication.*/PasswordAuthentication no/g' /etc/ssh/sshd_config
    fi
    sed -r -i 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/g' /etc/ssh/sshd_config
    sed -r -i 's/GSSAPIAuthentication.*/GSSAPIAuthentication no/g' /etc/ssh/ssh_config
    if [ ${SSH_ROOT_LOGIN} -eq 0 2>/dev/null ]; then
        sed -r -i 's/^#?PermitRootLogin.*/PermitRootLogin no/g' /etc/ssh/sshd_config
    fi
    sed -r -i 's/^#?UseDNS.*/UseDNS no/g' /etc/ssh/sshd_config
    /etc/rc.d/init.d/sshd restart

    ## profiles
    install -m 0644 ${TOP_DIR}/conf/profile/history.sh /etc/profile.d/history.sh
    install -m 0644 ${TOP_DIR}/conf/profile/path.sh /etc/profile.d/path.sh
    
    ## sysctl
    install -m 0644 ${TOP_DIR}/conf/sysctl/sysctl.conf /etc/sysctl.conf
    echo 'options ip_conntrack hashsize=131072' >> /etc/modprobe.d/openfwwf.conf
    sysctl -p

    ## System Handler
    echo  \* soft nofile 51200 >> /etc/security/limits.conf
    echo  \* hard nofile 51200 >> /etc/security/limits.conf

    ## timezone
cat > /etc/sysconfig/clock <<EOF
ZONE="Asia/Shanghai"
UTC=true
ARC=false
EOF
    install -m 0755 /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    tzdata-update
    ## config system service

    for SVC in auditd crond sshd sysstat;do
        chkconfig $SVC on 2>/dev/null
        service $SVC start 2>/dev/null
    done

    for SVC in ntpd fcoe ip6tables iptables iscsi iscsid lldpad lvm2-monitor;do
        chkconfig $SVC off 2>/dev/null
        service  $SVC stop 2>/dev/null
    done

## record installed tag
    echo 'CONFIG_SYS' >> ${INST_LOG}
else
    succ_msg "The current system has been alraedy conifgured and optimized!"
fi
