#!/bin/bash
# Firewall pessoal Linux by Zucco - 30/07/2012

# chkconfig: 35 30 70
# description: Firewall pessoal Linux
#
### BEGIN INIT INFO
# Provides: firewall_pessoal.sh
# Required-Start: $network
# Required-Stop:  
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description: Firewall pessoal Linux
### END INIT INFO

# variaveis

IPTABLES="/sbin/iptables"
IP6TABLES="/sbin/ip6tables"
IFEXT="eth0"


case $1 in
        stop)
            ${IPTABLES} -P OUTPUT ACCEPT
            ${IPTABLES} -P INPUT ACCEPT
            ${IPTABLES} -P FORWARD ACCEPT
            ${IPTABLES} -F
            ${IPTABLES} -X
            ${IPTABLES} -Z
            ${IPTABLES} -t nat -F
            ${IPTABLES} -t nat -X
            ${IPTABLES} -t mangle -F
            ${IPTABLES} -t mangle -X

	    # ipv6
            ${IP6TABLES} -P OUTPUT ACCEPT
            ${IP6TABLES} -P INPUT ACCEPT
            ${IP6TABLES} -P FORWARD ACCEPT
            ${IP6TABLES} -F
            ${IP6TABLES} -X
            ${IP6TABLES} -Z
            ${IP6TABLES} -t mangle -F
            ${IP6TABLES} -t mangle -X
		    
        ;;
        *)
            ${IPTABLES} -P OUTPUT ACCEPT
            ${IPTABLES} -P INPUT DROP 
            ${IPTABLES} -P FORWARD DROP
            ${IPTABLES} -F
            ${IPTABLES} -X
            ${IPTABLES} -Z 
            ${IPTABLES} -t nat -F
            ${IPTABLES} -t nat -X  
            ${IPTABLES} -t mangle -F
            ${IPTABLES} -t mangle -X

	    # ipv6
            ${IP6TABLES} -P OUTPUT DROP
            ${IP6TABLES} -P INPUT DROP
            ${IP6TABLES} -P FORWARD DROP
            ${IP6TABLES} -F
            ${IP6TABLES} -X
            ${IP6TABLES} -Z
            ${IP6TABLES} -t mangle -F
            ${IP6TABLES} -t mangle -X

	    # Sysctl Controls:	
            #filter ipspoofing
	    echo 2 > /proc/sys/net/ipv4/conf/all/rp_filter
            #stop responding to broadcast pings
	    echo 1 > /proc/sys/net/ipv4/icmp_echo_ignore_broadcasts
	    #block source routing
	    echo 0 > /proc/sys/net/ipv4/conf/all/accept_source_route
	    #kill timestamps
	    echo 0 > /proc/sys/net/ipv4/tcp_timestamps
            #activate the syncookies
	    echo 1 > /proc/sys/net/ipv4/tcp_syncookies
	    #disable redirects in the machine
	    echo 0 >/proc/sys/net/ipv4/conf/all/accept_redirects
	    #enable bad error message protection
	    echo 1 > /proc/sys/net/ipv4/icmp_ignore_bogus_error_responses
	    #block dynamic ip addresses
	    echo 0 > /proc/sys/net/ipv4/ip_dynaddr
	    #log packets with strange addresses
	    echo 1 > /proc/sys/net/ipv4/conf/all/log_martians

	    # disable ipv6
	    sysctl net.ipv6.conf.all.disable_ipv6=1


	    # Apesar de a política padrão ser DROP, bloqueia algumas coisas para evitar "barulho" nos logs:
            # Ignora Broadcasts
            ${IPTABLES} -A INPUT -d 255.255.255.255 -j DROP 
            #BCAST=$(ifconfig | grep Bcast | awk '{ print $4 }' | cut -d\: -f2)
            BCAST=$(/sbin/ip a | grep ${IFEXT} | grep brd | awk '{ print $4 }')
            ${IPTABLES} -A INPUT -d ${BCAST} -j DROP
            # Bad incoming source ip address 224.0.0.0/3
            ${IPTABLES} -A INPUT -s 224.0.0.0/3 -j DROP
            ${IPTABLES} -A INPUT -d 224.0.0.0/3 -j DROP
            # Block Fragments
            ${IPTABLES} -A INPUT -i ${IFEXT} -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
            ${IPTABLES} -A INPUT -i ${IFEXT} -f -j DROP


            # Block bad stuff
            ${IPTABLES} -A INPUT -m state --state INVALID -j DROP                   
	    ${IPTABLES} -A OUTPUT -m state --state INVALID -j DROP                  
	    ${IPTABLES} -A FORWARD -m state --state INVALID -j DROP 
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL ALL -j DROP
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets "
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL NONE -j DROP # NULL packets
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets "
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan "
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP


	    # Inicio das regras
            ${IPTABLES} -A INPUT -i lo -j ACCEPT
            ${IPTABLES} -A INPUT -i ${IFEXT} -m state --state ESTABLISHED,RELATED -j ACCEPT

	    # LOG
	    ${IPTABLES} -A INPUT -i ${IFEXT} -j LOG --log-level 4 --log-prefix "Firewall: "

        ;;
esac

