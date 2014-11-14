#!/bin/bash
#### percona-xtrabackup
if ! grep '^XTRABACKUP$' ${INST_LOG} > /dev/null 2>&1 ; then

## handle source packages
    file_proc ${XTRABACKUP_SRC}
    get_file
    unpack

    SYMLINK='/usr/local/percona-xtrabackup'

    mv ${STORE_DIR}/${SRC_DIR} ${INST_DIR}
    ln -sf ${INST_DIR}/${SRC_DIR} $SYMLINK 
    
## for install config files
    succ_msg "Begin to install ${SRC_DIR} config files"

## backup
    install -m 0700 ${TOP_DIR}/conf/percona-xtrabackup/xtrabackup.sh /usr/local/bin/xtrabackup.sh
    sed -i "s#^DATA_DIR.*#DATA_DIR=${XTRABACKUP_BACKUP_DIR}#" /usr/local/bin/xtrabackup.sh
    sed -i "s#password=#password=${MYSQL_ROOT_PASS}#" /usr/local/bin/xtrabackup.sh

## cron job
    echo '# MySQL Backup' >> /var/spool/cron/root
    echo '0 4 * * * /usr/local/bin/xtrabackup.sh' >> /var/spool/cron/root
    chown root:root /var/spool/cron/root
    chmod 600 /var/spool/cron/root

## record installed tag
    echo 'XTRABACKUP' >> ${INST_LOG}
else
    succ_msg "Percona Xtrabackup already installed!"
fi
