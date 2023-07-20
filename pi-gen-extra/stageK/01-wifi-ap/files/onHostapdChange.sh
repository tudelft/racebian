#!/bin/bash
if [[ $2 == "AP-STA-CONNECTED" ]]
then
    sleep 2
    # connected client should now be in the ARP table, so we can poll its IP from there
    # take only last hit (tail -1) in case there are multiple
    CLIENT_IP="$(arp -n | grep $3 | tail -1 | awk '{print $1}')"
    # TODO: why not get this from dhcpcd directly somehow?

    # add as gateway
    route add default gw ${CLIENT_IP} wlan0
fi

if [[ $2 == "AP-STA-DISCONNECTED" ]]
then
    # hope it's still in arp table
    CLIENT_IP="$(arp -n | grep $3 | tail -1 | awk '{print $1}')"

    # add as gateway
    route del default gw ${CLIENT_IP} wlan0
fi