#!/bin/bash

## Collect hardware information
readonly MEM_TOTAL=$(free -m | grep 'Mem:' | awk '{print $2}')
readonly CPU_VENDOR=$(cat /proc/cpuinfo | grep 'vendor_id' | head -n 1 | awk -F ': ' '{print $2}')
readonly CPU_TYPE=$(cat /proc/cpuinfo | grep 'model name' | head -n 1 | awk -F ': ' '{print $2}' | awk -F '@ ' '{print $1}')
readonly CPU_SPEED=$(cat /proc/cpuinfo | grep 'model name' | head -n 1 | awk -F ': ' '{print $2}' | awk -F '@ ' '{print $2}')
readonly CPU_NUM=$(cat /proc/cpuinfo | grep 'processor' | wc -l)
readonly HD_NUM=$(fdisk -l | grep '^Disk /dev/' | wc -l)
