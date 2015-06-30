#!/bin/bash

if [ ! -f "${INST_LOG}" ];then
    warn_msg "${INST_LOG} not found!"
    warn_msg "Maybe you did not install Moss on your system!"
    fail_msg "Quit Moss uninstallation!"
fi

## uninstall MySQL
if grep '^MYSQL$' ${INST_LOG} > /dev/null 2>&1 ; then
    DEL_MYSQL_INPUT=0
    while [ ${DEL_MYSQL_INPUT} -eq 0 ]; do
        read -p "Do you wish to remove MySQL Server?(y/N)" DEL_MYSQL
        if [[ "${DEL_MYSQL}" = 'y' ]] || [[ "${DEL_MYSQL}" = 'Y' ]];then
            DEL_MYSQL=y
            DEL_MYSQL_INPUT=1
        elif [[ -z "${DEL_MYSQL}" ]] || [[ "${DEL_MYSQL}" = 'n' ]] || [[ "${DEL_MYSQL}" = 'N' ]];then
            DEL_MYSQL=n
            DEL_MYSQL_INPUT=1
        else
            warn_msg "You can only input y or n."
            DEL_MYSQL_INPUT=0
        fi
    done

    succ_msg "\nStarting Uninstall MySQL Server...\n"
    if [ "${DEL_MYSQL}" = 'y' ];then
        BAK_MYSQL_DATA_INPUT=0
        while [ ${BAK_MYSQL_DATA_INPUT} -eq 0 ]; do
            read -p "Do you wish to keep MySQL database?(Y/n)" BAK_MYSQL_DATA
            if [[ -z "${BAK_MYSQL_DATA}" ]] || [[ "${BAK_MYSQL_DATA}" = 'y' ]] || [[ "${BAK_MYSQL_DATA}" = 'Y' ]];then
                BAK_MYSQL_DATA=y
                BAK_MYSQL_DATA_INPUT=1
            elif [[ "${BAK_MYSQL_DATA}" = 'n' ]] || [[ "${BAK_MYSQL_DATA}" = 'N' ]];then
                BAK_MYSQL_DATA=n
                BAK_MYSQL_DATA_INPUT=1
            else
                warn_msg "You can only input y or n."
                BAK_MYSQL_DATA_INPUT=0
            fi
        done

        BAK_MYSQL_CONF_INPUT=0
        while [ ${BAK_MYSQL_CONF_INPUT} -eq 0 ]; do
            read -p "Do you wish to keep MySQL my.cnf?(Y/n)" BAK_MYSQL_CONF
            if [[ -z "${BAK_MYSQL_CONF}" ]] || [[ "${BAK_MYSQL_CONF}" = 'y' ]] || [[ "${BAK_MYSQL_CONF}" = 'Y' ]];then
                BAK_MYSQL_CONF=y
                BAK_MYSQL_CONF_INPUT=1
            elif [[ "${BAK_MYSQL_CONF}" = 'n' ]] || [[ "${BAK_MYSQL_CONF}" = 'N' ]];then
                BAK_MYSQL_CONF=n
                BAK_MYSQL_CONF_INPUT=1
            else
                warn_msg "You can only input y or n."
                BAK_MYSQL_CONF_INPUT=0
            fi
        done

        BAK_MYSQL_BACK_INPUT=0
        while [ ${BAK_MYSQL_BACK_INPUT} -eq 0 ]; do
            read -p "Do you wish to keep MySQL database backup?(Y/n)" BAK_MYSQL_BACK
            if [[ -z "${BAK_MYSQL_BACK}" ]] || [[ "${BAK_MYSQL_BACK}" = 'y' ]] || [[ "${BAK_MYSQL_BACK}" = 'Y' ]];then
                BAK_MYSQL_BACK=y
                BAK_MYSQL_BACK_INPUT=1
            elif [[ "${BAK_MYSQL_BACK}" = 'n' ]] || [[ "${BAK_MYSQL_BACK}" = 'N' ]];then
                BAK_MYSQL_BACK=n
                BAK_MYSQL_BACK_INPUT=1
            else
                warn_msg "You can only input y or n."
                BAK_MYSQL_BACK_INPUT=0
            fi
        done

        warn_msg "Stop MySQL Server..."
        /etc/init.d/mysqld stop
        sleep 3
        if (pstree | grep mysqld > /dev/null 2>&1) ; then
            fail_msg "MySQL Server Fail to Stop!"
        else
            succ_msg "MySQL Server Stoped!"
        fi

        rm -f /usr/local/mysql
        rm -rf ${INST_DIR}/Percona-Server-*
        rm -rf ${INST_DIR}/mysql-*
        rm -f /usr/local/percona-xtrabackup
        rm -rf ${INST_DIR}/percona-xtrabackup-*
        rm -rf /var/log/mysql
        rm -f /usr/local/bin/xtrabackup.sh
        rm -f /usr/local/etc/logrotate/mysql
        sed -i "/.*# Logrotate - MySQL.*/d" /var/spool/cron/root
        sed -i "/.*\/usr\/local\/etc\/logrotate\/mysql.*/d" /var/spool/cron/root
        sed -i "/.*# MySQL Backup.*/d" /var/spool/cron/root
        sed -i "/.*\/usr\/local\/bin\/xtrabackup\.sh.*/d" /var/spool/cron/root
        if [ "${BAK_MYSQL_DATA}" = 'n' ];then
            rm -rf ${MYSQL_DATA_DIR}
        fi
        if [ "${BAK_MYSQL_CONF}" = 'n' ];then
            rm -f /etc/my.cnf
        fi
        if [ "${BAK_MYSQL_BACK}" = 'n' ];then
            rm -f ${XTRABACKUP_BACKUP_DIR}
        fi

        chkconfig --del mysqld
        rm -f /etc/init.d/mysqld

        rm -f /root/.my.cnf
        rm -f /root/.mysql_history

        userdel -r mysql 2>/dev/null

        sed -i "/^MYSQL\$/d" ${INST_LOG}
        sed -i "/^XTRABACKUP\$/d" ${INST_LOG}

        succ_msg "MySQL Server has been removed from your system!"
        sleep 3
    fi
fi
