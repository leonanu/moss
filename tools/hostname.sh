#!/bin/bash

OLD_HOSTNAME="$(hostname)"
NEW_HOSTNAME="$1"

if [ -z "$NEW_HOSTNAME" ]; then
    echo -n "Please enter new hostname: "
    read NEW_HOSTNAME < /dev/tty
fi

if [ -z "$NEW_HOSTNAME" ]; then
    echo "Error: No hostname entered. Exiting."
    exit 1
fi

echo "Changing hostname from $OLD_HOSTNAME to $NEW_HOSTNAME..."

hostname "$NEW_HOSTNAME"

sed -i "s/HOSTNAME=.*/HOSTNAME=$NEW_HOSTNAME/g" /etc/sysconfig/network

if [ -n "$( grep "$OLD_HOSTNAME" /etc/hosts )" ]; then
    sed -i "s/$OLD_HOSTNAME//g" /etc/hosts
fi

sed -i "s/127\.0\.0\.1.*/127.0.0.1    $NEW_HOSTNAME localhost localhost.localdomain/" /etc/hosts