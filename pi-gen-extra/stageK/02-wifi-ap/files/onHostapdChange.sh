#!/bin/bash

LOG_FILE=/var/log/onHostapdChange.log
ARP_RETRIES=10
SLEEP_PERIOD=2
i=0

echo "Invoked at $(date --rfc-3339=seconds) with arguments $1 $2 $3" >> $LOG_FILE

if [[ $2 == "AP-STA-CONNECTED" ]]
then
    while [ $i -lt $ARP_RETRIES ]
    do
        # connected client should now be in the ARP table, so we can poll its IP from there
        # take only last hit (tail -1) in case there are multiple
        CLIENT_IP="$(arp -n | grep $3 | tail -1 | awk '{print $1}')"
        echo "Connect attempt $i: found CLIENT_IP $CLIENT_IP" >> $LOG_FILE
        if [[ $CLIENT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            # add as gateway
            echo "Adding route $CLIENT_IP" >> $LOG_FILE
            route add default gw $CLIENT_IP wlan0
            break
        fi

        # fail, lets wait, maybe dhcpcd takes too long..
        sleep $SLEEP_PERIOD
        let "i++"
    done
fi

if [[ $2 == "AP-STA-DISCONNECTED" ]]
then
    # hope it's still in arp table
    CLIENT_IP="$(arp -n | grep $3 | tail -1 | awk '{print $1}')"

    # add as gateway
    echo "Disconnect attempt $i: found CLIENT_IP $CLIENT_IP" >> $LOG_FILE
    if [[ $CLIENT_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        route del default gw $CLIENT_IP wlan0
    fi
fi
