#!/bin/bash

mkdir -p /var/spool/usbip/

SPOOL=/var/spool/usbip/attach

if [[ $2 == "-q" ]]
then
    exec &>/dev/null
fi

touch $SPOOL

while [[ -e $SPOOL ]]
do
    /usr/bin/usbip attach -r "$1" -b 1-1
    sleep 3 
done

/usr/bin/usbip detach -p 0

exit 0
