#!/bin/bash

DATE=$(date +%Y%m%d)
RM_DATE=$(date --date '7 days ago' +'%Y%m%d')

BACKUP_DIR=${XTRABACKUP_BACKUP_DIR}

[ ! -d ${BACKUP_DIR} ] && mkdir -p full-${BACKUP_DIR}

# Full database backup
/usr/local/percona-xtrabackup/bin/innobackupex --defaults-file=/etc/my.cnf --user=root --password= --no-timestamp ${BACKUP_DIR}/${DATE}

# Compress
# cd ${BACKUP_DIR} && tar czf mysql-${DATE}.tar.gz ${DATE}  && rm -rf ${DATE}

# Delete backup over 7 days
rm -rf ${BACKUP_DIR}/full-${RM_DATE}
