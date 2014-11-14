#!/bin/bash
if ! grep '^SERVICES$' ${INST_LOG} > /dev/null 2>&1 ;then
    for SRV in 'atd rpcbind portmap';do
        service $SRV stop
        chkconfig --level 35 $SRV off
    done

    for SRV in 'crond nginx php-fpm mysql redis';do
        service $SRV start
        chkconfig --level 35 $SRV on
    done
    ## record installed tag    
    echo 'SERVICES' >> ${INST_LOG}
else
    succ_msg "ntsysV services has been already processed!"
fi
