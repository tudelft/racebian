#!/bin/bash

# https://unix.stackexchange.com/questions/406847/use-usbip-for-devices-that-are-being-removed-and-reconnected

# hardcode USB port
USB_PORT=1-1

SPOOL=/var/spool/usbip/bind

if [[ $1 == "-q" ]]
then
    exec &>/dev/null
fi

touch $SPOOL

while [[ -e $SPOOL ]]
do
  /usr/sbin/usbip bind -b "$USB_PORT"
# a little bit beun
  sleep 3
done

/usr/sbin/usbip unbind -b "$USB_PORT"

exit 0