#!/bin/bash

DATE=$(date +%Y%m%d)
RM_DATE=$(date --date '7 days ago' +'%Y%m%d')

BACKUP_DIR=${XTRABACKUP_BACKUP_DIR}
BACKUP_LOG=${BACKUP_DIR}/backup.log

[ ! -d ${BACKUP_DIR} ] && mkdir -p ${BACKUP_DIR}

# Full database backup
START_TIME=$(date "+%Y-%m-%d %H:%M:%S")
/usr/local/percona-xtrabackup/bin/innobackupex --defaults-file=/etc/my.cnf --user=root --password= --no-timestamp --no-lock ${BACKUP_DIR}/full-${DATE}
END_TIME=$(date "+%Y-%m-%d %H:%M:%S")

# Compress
# cd ${BACKUP_DIR} && tar czf full-${DATE}.tar.gz full-${DATE}  && rm -rf full-${DATE}

sleep 5
BACKUP_FILE_SIZE=$(du -sh ${BACKUP_DIR}/full-${DATE} | awk '{print $1}')
echo -ne "Begin Time : ${START_TIME}\n" >> ${BACKUP_LOG}
echo -ne "Finish Time: ${END_TIME}\n" >> ${BACKUP_LOG}
echo -ne "Backup File Name: ${BACKUP_DIR}/full-${DATE}\n" >> ${BACKUP_LOG}
echo -ne "Backup File Size: ${BACKUP_FILE_SIZE}\n\n" >> ${BACKUP_LOG}

# Delete backup over 7 days
rm -rf ${BACKUP_DIR}/full-${RM_DATE}
