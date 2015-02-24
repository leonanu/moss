#!/bin/bash
#set -x
#set -u

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/sbin:/usr/local/mysql/bin:/usr/local/percona-xtrabackup/bin
export HOME=/var/empty

DATE=$(date +%Y%m%d)
RM_DATE=$(date --date '10 days ago' +'%Y%m%d')

BACKUP_DIR=${XTRABACKUP_BACKUP_DIR}

[ ! -d ${BACKUP_DIR} ] && mkdir -p ${BACKUP_DIR}

# Full database backup
/usr/local/percona-xtrabackup/bin/innobackupex --defaults-file=/etc/my.cnf --user=root --password= --no-timestamp ${BACKUP_DIR}/${DATE}

# Compress
# cd ${BACKUP_DIR} && tar czf mysql-${DATE}.tar.gz ${DATE}  && rm -rf ${DATE}

# Delete backup over 10 days
rm -rf ${BACKUP_DIR}/${RM_DATE}
