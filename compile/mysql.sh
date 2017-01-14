#!/bin/bash
#### mysql-5.6.x
if ! grep '^MYSQL$' ${INST_LOG} > /dev/null 2>&1 ; then

## check proc
    proc_exist mysqld
    if [ ${PROC_FOUND} -eq 1 ];then
        fail_msg "MySQL is running on this host!"
    fi

## handle source packages
    file_proc ${MYSQL_SRC}
    get_file
    unpack

    SYMLINK='/usr/local/mysql'
    SERVER_ID=$(ip -f inet addr show dev ${NIC_WAN}|awk '$1~/inet/{print $2}'|cut -d/ -f1|cut -d. -f3,4|tr -d .)

    mv ${STORE_DIR}/${SRC_DIR} ${INST_DIR}
    ln -sf ${INST_DIR}/${SRC_DIR} $SYMLINK 
    id mysql >/dev/null 2>&1 || useradd mysql -u 1002 -M -s /sbin/nologin
    [ ! -d $MYSQL_DATA_DIR ] && mkdir -m 0755 -p $MYSQL_DATA_DIR
    install -m 0644 ${TOP_DIR}/conf/mysql/my.cnf /etc/my.cnf
    sed -i "s#server_id.*#server_id=${SERVER_ID}#" /etc/my.cnf
    sed -i "s#datadir.*#datadir=${MYSQL_DATA_DIR}#" /etc/my.cnf
    sed -i "s#innodb_data_home_dir.*#innodb_data_home_dir=${MYSQL_DATA_DIR}#" /etc/my.cnf
    sed -i "s#innodb_log_group_home_dir.*#innodb_log_group_home_dir=${MYSQL_DATA_DIR}#" /etc/my.cnf
    chown -R mysql:mysql ${INST_DIR}/${SRC_DIR}
    cd $SYMLINK
    ./scripts/mysql_install_db --user=mysql --defaults-file=/etc/my.cnf --force --skip-name-resolve
    sleep 1
    chown mysql:mysql -R $MYSQL_DATA_DIR

## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"

    ## log
    [ ! -d /var/local/mysql ] && mkdir -m 0755 -p /var/log/mysql
    [ ! -d /usr/local/etc/logrotate ] && mkdir -m 0755 -p /usr/local/etc/logrotate
    chown mysql:mysql -R /var/log/mysql
    install -m 0644 ${TOP_DIR}/conf/mysql/mysql.logrotate /usr/local/etc/logrotate/mysql

    ## cron job
    echo '' >> /var/spool/cron/root
    echo '# Logrotate - MySQL' >> /var/spool/cron/root
    echo '0 0 * * * /usr/sbin/logrotate -f /usr/local/etc/logrotate/mysql > /dev/null 2>&1' >> /var/spool/cron/root
    chown root:root /var/spool/cron/root
    chmod 600 /var/spool/cron/root

    ## init scripts
    install -m 0755 ${SYMLINK}/support-files/mysql.server /etc/init.d/mysqld
    chkconfig --add mysqld
    chkconfig --level 35 mysqld on
    ## start
    service mysqld start
    sleep 3

## check proc
    proc_exist mysqld
    if [ ${PROC_FOUND} -eq 0 ];then
        fail_msg "MySQL failed to start!"
    fi

    ## Set MySQL root password
    #MYSQL_ROOT_PASS0=0
    #while [ $MYSQL_ROOT_PASS0 -eq 0 ]; do
    #    read -p "Please set MySQL root password:" MYSQL_ROOT_PASS1
    #    read -p "Input the root password again :" MYSQL_ROOT_PASS2
    #    if [ $MYSQL_ROOT_PASS1 = $MYSQL_ROOT_PASS2 ]; then
    #        MYSQL_ROOT_PASS0=1
    #    else
    #        warn_msg "The two password you input are not matched!"
    #        MYSQL_ROOT_PASS0=0
    #    fi
    #done

    MYSQL_ROOT_PASS=$(mkpasswd -s 0 -l 12)
    MYSQL_MULADMIN_PASS=$(mkpasswd -s 0 -l 12)
    /usr/local/mysql/bin/mysqladmin -uroot password "${MYSQL_ROOT_PASS}"
    /usr/local/mysql/bin/mysqladmin -h127.0.0.1 -uroot password "${MYSQL_ROOT_PASS}" 

    ## /root/.my.cnf
    echo '[client]' > /root/.my.cnf
    echo 'user = root' >> /root/.my.cnf
    echo "password = ${MYSQL_ROOT_PASS}" >> /root/.my.cnf
    echo '' >> /root/.my.cnf
    echo '[mysqladmin]' >> /root/.my.cnf
    echo "user = ${MYSQL_MULADMIN_USER}" >> /root/.my.cnf
    echo "password = ${MYSQL_MULADMIN_PASS}" >> /root/.my.cnf
    chmod 600 /root/.my.cnf
    succ_msg "MySQL root password has been changed!"
    warn_msg "Please protect the Moss config file CARFULLY!"
    read -p 'Press any key to continue.'

    ## remove null username & password accounts
    /usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e 'USE mysql; DELETE FROM user WHERE password=""; FLUSH PRIVILEGES;'

    ## create mysqladmin user account
    /usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT SHUTDOWN ON *.* TO '${MYSQL_MULADMIN_USER}'@'localhost' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"
    /usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT SHUTDOWN ON *.* TO '${MYSQL_MULADMIN_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"
    /usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT RELOAD ON *.* TO '${MYSQL_MULADMIN_USER}'@'localhost' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"
    /usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e "GRANT RELOAD ON *.* TO '${MYSQL_MULADMIN_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_MULADMIN_PASS}'; FLUSH PRIVILEGES;"

    ## remove database 'test'
    /usr/local/mysql/bin/mysql -uroot -p${MYSQL_ROOT_PASS} -e 'DROP DATABASE test;'

    ## record installed tag
    echo 'MYSQL' >> ${INST_LOG}
else
    succ_msg "MySQL already installed!"
fi
