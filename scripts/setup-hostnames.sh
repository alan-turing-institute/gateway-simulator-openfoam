#!/bin/bash

# Dynamically gets the current IP address of the container
# and adds a line with this IP and the static name FIXEDHOSTNAME
# to the /etc/hosts - this is needed by torque
# Also, avoid doing it twice

FIXEDHOSTNAME='simulator'
# Get current IP
IP=$(ip -4 addr show eth0| grep -Po 'inet \K[\d.]+')

if [ grep "$FIXEDHOSTNAME" > /dev/null 2>&1 ]
then
    echo Hostname already set to $FIXEDHOSTNAME
else
    echo "$IP $FIXEDHOSTNAME" >> /etc/hosts
fi
