#!/bin/sh 

MYSQL_SOCK="/tmp/mysql.sock" 
ARGS=1 
if [ $# -ne "$ARGS" ];then 
    echo "Please input one arguement:" 
fi 
case $1 in 
    Uptime) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK status|cut -f2 -d":"|cut -f1 -d"T"` 
            echo $result 
            ;; 
        Com_update) 
            result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_update"|cut -d"|" -f3` 
            echo $result 
            ;; 
        Slow_queries) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK status |cut -f5 -d":"|cut -f1 -d"O"` 
                echo $result 
                ;; 
    Com_select) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_select"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_rollback) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_rollback"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Questions) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK status|cut -f4 -d":"|cut -f1 -d"S"` 
                echo $result 
                ;; 
    Com_insert) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_insert"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_delete) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_delete"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_commit) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_commit"|cut -d"|" -f3` 
                echo $result 
                ;; 
    Bytes_sent) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Bytes_sent" |cut -d"|" -f3` 
                echo $result 
                ;; 
    Bytes_received) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Bytes_received" |cut -d"|" -f3` 
                echo $result 
                ;; 
    Com_begin) 
        result=`/usr/local/mysql/bin/mysqladmin --defaults-extra-file=/home/zabbix/.my.cnf -umulti_admin -S $MYSQL_SOCK extended-status |grep -w "Com_begin"|cut -d"|" -f3` 
                echo $result 
                ;; 
                        
        *) 
        echo "Usage:$0(Uptime|Com_update|Slow_queries|Com_select|Com_rollback|Questions)" 
        ;; 
esac
