#!/bin/bash

if [[ $USER != "root" ]]
then
    echo "Must be run as root. Exiting"
    exit 1
fi

# setup routing to provide internet to the pi
function help_and_exit {
    echo "usage: $0 --iface=[network_interface] [remote_ip]";
    echo ""
    echo "If no --iface, then $0 will take all interfaces that do not route 10.0.0.1"
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

# last argument must be ip
ip route get $right > /dev/null 2>&1
if [[ $? -gt 0 ]]
then
    echo "Last argument must be a valid ip"
    help_and_exit
fi

IP=$right

## now do stuff

up_iface_routes() {
    iface=$1
    ip=$2
    # docker changes the default filter FORWARD policy from ACCEPT to DROP.
    # fix that with an explicit rule that allows outbound from the pi by default,
    # but inbound only for related or established connections that originated from
    # the pi (see Unix conntrack)
    iptables -t filter -C FORWARD -s $ip -o "${iface}" -j ACCEPT > /dev/null 2>&1 ||
        iptables -t filter -A FORWARD -s $ip -o "${iface}" -j ACCEPT
    iptables -t filter -C FORWARD -d $ip -i "${iface}" -m state --state RELATED,ESTABLISHED -j ACCEPT > /dev/null 2>&1 ||
        iptables -t filter -A FORWARD -d $ip -i "${iface}" -m state --state RELATED,ESTABLISHED -j ACCEPT

    # create a new chain for interface forwarding, unless exists
    iptables -t nat -n --list fw-pi-$iface > /dev/null 2>&1
    if [[ $? -gt 0 ]]
    then
        iptables -t nat -N fw-pi-$iface
    fi

    # flush all of its rules in case it exists already
    #iptables -t nat -F fw-pi-$iface

    # fwd all source 10.0.0.1 traffic to the new chain (delete then add to ensure only one)
    iptables -t nat -C POSTROUTING -s $ip -j fw-pi-$iface > /dev/null 2>&1 ||
        iptables -t nat -A POSTROUTING -s $ip -j fw-pi-$iface

    # allow outbound traffic on the iface that has connection to the internet gateway
    iptables -t nat -C fw-pi-$iface -o "${iface}" -s $ip -j MASQUERADE > /dev/null 2>&1 ||
        iptables -t nat -A fw-pi-$iface -o "${iface}" -s $ip -j MASQUERADE

    echo "Finished attempting iptables setup for $ip through ${iface}"
}

# enable routing
sysctl -w net.ipv4.ip_forward=1 > /dev/null

mkdir -p /var/spool/pi-routed-interfaces

if [[ -z $IFACE ]]
then
    #IFACE=$(route -n | grep "^0.0.0.0" | grep -v "$IP" | head -1 | awk '{print $8}')
    #echo "Guessing that interface ${IFACE} has internet access and using it."
    ip_iface=$(ip route get $IP | grep -Po 'dev \K[^\s]*')
    ifaces=$(route -n | awk '{if($4 ~ /G/) print $8}' | grep -v $ip_iface | sort | uniq)
    echo "Guessing that these are all relevant interfaces that to don't route to $IP:"
    echo $ifaces
    for iface in $ifaces
    do
        up_iface_routes $iface $IP
        echo "$IP" >> /var/spool/pi-routed-interfaces/$iface
    done
fi

