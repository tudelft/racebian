#!/bin/bash

if [[ $USER != "root" ]]
then
    echo "Must be run as root. Exiting"
    exit 1
fi

# down routing to provide internet to the pi
function help_and_exit {
    echo "usage: $0 --iface=[network_interface]";
    echo ""
    echo "If no --iface given, then all current routes will be downed."
    exit 1;
}

# handle arguments
#deploy=$(echo "$@" | awk -F= '{a[$1]=$2} END {print(a["--deploy"])}')
# key-value pairs (HOW IS THERE NOT A BUILT IN FOR THIS?)
processes=8
while test $# != 0
do
    left=$(echo "$1" | cut -d "=" -f 1)
    right=$(echo "$1" | cut -d "=" -f 2)
    case "$left" in
    --iface) IFACE=$right ;;
    --help) help_and_exit ;;
    -h) help_and_exit ;;
    esac
    shift
done

## actual stuff
down_iface_routes() {
    iface=$1
    ip=$2
    # do not forward POSTROUTING to fw-pi chain (ignore errors if rule already deleted)
	iptables -t nat -D POSTROUTING -s $ip -j fw-pi-$iface
    # flush fw-pi table
	iptables -t nat -D fw-pi-$iface -o $iface -s $ip -j MASQUERADE > /dev/null 2>&1
    # delete fw-pi tables, if empry and not referenced anymore, other dont care
	iptables -t nat -X fw-pi-$iface > /dev/null 2>&1
    # delete accept rule in filter table
	iptables -t filter -D FORWARD -s $ip -o "$iface" -j ACCEPT
	iptables -t filter -D FORWARD -d $ip -i "$iface" -m state --state RELATED,ESTABLISHED -j ACCEPT
}

if [[ -z $IFACE ]]
then
    routed_ifaces="/var/spool/pi-routed-interfaces/*"
else
    routed_ifaces="/var/spool/pi-routed-interfaces/$IFACE"
fi

for routed_iface in $routed_ifaces
do
    if [[ ! -f $routed_iface ]]
    then
        echo "no routed interfaces detected"
        exit 1
    fi

    iface=$(basename $routed_iface)
    # get ips from spool file
    ips=$(cat $routed_iface | sort | uniq)
    for ip in $ips
    do
        echo "downing routing of $ip through $iface"
        down_iface_routes $iface $ip
    done
    rm $routed_iface
done

# disable routing
sysctl -w net.ipv4.ip_forward=0 > /dev/null 2>&1
