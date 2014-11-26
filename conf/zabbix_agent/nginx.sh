#!/bin/bash 
BKUP_DATE=`/bin/date +%Y%m%d` 
HOST=$(/sbin/ifconfig eth0 |grep "inet addr" |awk -F[:" "] '{print $13}')
PORT="80" 

ARGS=1
if [ $# -ne "$ARGS" ];then
    echo "Please input an arguement:" 
fi
case $1 in
    active)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| grep 'Active' | awk '{print $NF}')
        echo $result
        ;;
    reading)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| grep 'Reading' | awk '{print $2}')
        echo $result
        ;;
    writing)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| grep 'Writing' | awk '{print $4}')
        echo $result
        ;;
    waiting)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| grep 'Waiting' | awk '{print $6}')
        echo $result
        ;;
    accepts)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| awk NR==3 | awk '{print $1}')
        echo $result
        ;;
    handled)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| awk NR==3 | awk '{print $2}')
        echo $result
        ;;
    requests)
        result=$(/usr/bin/curl "http://$HOST:$PORT/status" 2>/dev/null| awk NR==3 | awk '{print $3}')
        echo $result
        ;;
    *)
        echo "Usage:$0(active|reading|writing|waiting|accepts|handled|requests)"
        ;;
esac
